
import psycopg2
import psycopg2.extras
import os
from datetime import datetime, timedelta


# Lee las credenciales de las variables de entorno para mayor seguridad
#definimos las credenciales para el acceso  a las bases de datos
OLTP_DB_HOST = os.getenv("OLTP_DB_HOST", "localhost")
OLTP_DB_PORT = os.getenv("OLTP_DB_PORT", "5432")
OLTP_DB_NAME = os.getenv("OLTP_DB_NAME", "oltp_db")
OLTP_DB_USER = os.getenv("OLTP_DB_USER", "user_oltp")
OLTP_DB_PASSWORD = os.getenv("OLTP_DB_PASSWORD", "password_oltp")
#credenciales de la base de datos análitica
OLAP_DB_HOST = os.getenv("OLAP_DB_HOST", "localhost")
OLAP_DB_PORT = os.getenv("OLAP_DB_PORT", "5433")
OLAP_DB_NAME = os.getenv("OLAP_DB_NAME", "olap_db")
OLAP_DB_USER = os.getenv("OLAP_DB_USER", "user_olap")
OLAP_DB_PASSWORD = os.getenv("OLAP_DB_PASSWORD", "password_olap")



def get_last_run_timestamp():
    """
    Obtiene el timestamp de la última ejecución exitosa del ETL.
    Si no existe, devuelve una fecha de hace 7 días.
    """
    try:
        with open("last_run.txt", "r") as f:
            return datetime.fromisoformat(f.read().strip())
    except FileNotFoundError:
        return datetime.now() - timedelta(days=7)

def save_last_run_timestamp():
    """
    Guarda el timestamp actual como la última ejecución exitosa.
    """
    with open("last_run.txt", "w") as f:
        f.write(datetime.now().isoformat())

def extract_new_transactions(conn_oltp, last_run_timestamp):
    """
    Extrae transacciones de ventas y entradas de mercancía desde la última ejecución.
    
    Args:
        conn_oltp: Conexión a la base de datos OLTP.
        last_run_timestamp: Timestamp de la última ejecución.
        
    Returns:
        Una lista de tuplas con los datos de las transacciones.
    """
    with conn_oltp.cursor(cursor_factory=psycopg2.extras.DictCursor) as cursor:
        cursor.execute("""
            SELECT
                it.producto_id,
                t.tipo_transaccion,
                it.cantidad,
                it.costo_unitario_compra,
                it.precio_unitario_venta,
                t.fecha_hora
            FROM items_transaccion it
            JOIN transacciones t ON it.transaccion_id = t.transaccion_id
            WHERE t.fecha_hora > %s
              AND t.estado = 'COMPLETADA'
              AND t.tipo_transaccion IN ('VENTA', 'ENTRADA_MERCANCIA')
            ORDER BY t.fecha_hora ASC;
        """, (last_run_timestamp,))
        return cursor.fetchall()



def load_data_into_olap(conn_olap, transactions):
    """
    Carga los datos de las transacciones en la base de datos OLAP.
    
    Args:
        conn_olap: Conexión a la base de datos OLAP.
        transactions: Lista de transacciones a cargar.
    """
    with conn_olap.cursor() as cursor:
        for trx in transactions:
            try:
                if trx['tipo_transaccion'] == 'ENTRADA_MERCANCIA':
                    # Llama a la función de la base de datos para actualizar el costo promedio
                    cursor.execute(
                        "SELECT actualizar_costo_promedio(%s, %s, %s);",
                        (trx['producto_id'], trx['cantidad'], trx['costo_unitario_compra'])
                    )
                elif trx['tipo_transaccion'] == 'VENTA':
                    # Llama a la función de la base de datos para actualizar el stock
                    cursor.execute(
                        "SELECT actualizar_stock_venta(%s, %s);",
                        (trx['producto_id'], trx['cantidad'])
                    )
                
                # Opcional: recalcular precio sugerido después de una entrada
                if trx['tipo_transaccion'] == 'ENTRADA_MERCANCIA':
                    cursor.execute(
                        "SELECT calcular_precio_sugerido(%s);",
                        (trx['producto_id'],)
                    )

            except psycopg2.Error as e:
                print(f"Error procesando transacción para producto {trx['producto_id']}: {e}")
                conn_olap.rollback()  # Deshace la transacción actual si hay un error
                # Considerar un mecanismo de reintento o logging a un sistema externo
            else:
                conn_olap.commit() # Confirma la transacción si fue exitosa

def refresh_materialized_views(conn_olap):
    """
    Refresca las vistas materializadas en la base de datos OLAP.
    """
    with conn_olap.cursor() as cursor:
        
        cursor.execute("SELECT refrescar_vistas_materializadas();")
        conn_olap.commit()
        




def main():
    """
    Función principal que orquesta el proceso ETL.
    """
    print("Iniciando proceso ETL semanal...")
    
    conn_oltp = None
    conn_olap = None
    
    try:
        # 1. Conectar a las bases de datos
        conn_oltp = psycopg2.connect(
            host=OLTP_DB_HOST,
            port=OLTP_DB_PORT,
            dbname=OLTP_DB_NAME,
            user=OLTP_DB_USER,
            password=OLTP_DB_PASSWORD
        )
    

        conn_olap = psycopg2.connect(
            host=OLAP_DB_HOST,
            port=OLAP_DB_PORT,
            dbname=OLAP_DB_NAME,
            user=OLAP_DB_USER,
            password=OLAP_DB_PASSWORD
        )
        print("Conexión OLAP exitosa.")

        # 2. Extraer datos
        last_run = get_last_run_timestamp()
        print(f"Extrayendo transacciones desde: {last_run}")
        new_transactions = extract_new_transactions(conn_oltp, last_run)
        
        if not new_transactions:
            print("No hay transacciones nuevas para procesar.")
            return

        print(f"Se encontraron {len(new_transactions)} transacciones nuevas.")

        # 3. Cargar datos
        print("Cargando datos en la base de datos OLAP...")
        load_data_into_olap(conn_olap, new_transactions)
        print("Carga de datos completada.")

        # 4. Post procesamiento en OLAP
        refresh_materialized_views(conn_olap)

        # 5. Guardar timestamp de ejecución
        save_last_run_timestamp()
        print(f"Proceso ETL completado exitosamente a las {datetime.now()}.")

    except psycopg2.OperationalError as e:
        print(f"Error de conexión: {e}")
    except Exception as e:
        print(f"Ocurrió un error :(: {e}")
    finally:
        # 6. Cerrar conexiones
        if conn_oltp:
            conn_oltp.close()
            print("Conexión OLTP cerrada.")
        if conn_olap:
            conn_olap.close()
            print("Conexión OLAP cerrada.")

if __name__ == "__main__":
    main()
