
# Proceso ETL para Sincronizar OLTP y OLAP

## Propósito

Este script de Python es un proceso de Extracción, Transformación y Carga (ETL) diseñado para mover datos transaccionales desde una base de datos OLTP (procesamiento de transacciones en línea) a una base de datos OLAP (procesamiento analítico en línea). El objetivo es mantener la base de datos OLAP actualizada con la información más reciente de ventas y entradas de mercancía para análisis de negocio.

El script está diseñado para ser ejecutado periódicamente (por ejemplo, semanalmente) a través de un `cronjob` o un orquestador de tareas similar.

## Características

- **Incremental**: Solo procesa transacciones nuevas desde la última ejecución exitosa, evitando la duplicación de datos y optimizando el rendimiento.
- **Robusto**: Utiliza funciones almacenadas en la base de datos OLAP para manejar la lógica de negocio compleja (cálculo de costo promedio, actualización de stock), garantizando la integridad de los datos.
- **Seguro**: La configuración de la base de datos se gestiona a través de variables de entorno para evitar credenciales hardcodeadas en el código.
- **Mantenimiento Automatizado**: Refresca automáticamente las vistas materializadas en la base de datos OLAP después de cada carga de datos, asegurando que los dashboards (por ejemplo, en Apache Superset) siempre muestren información actualizada.

## Requisitos Previos

- Python 3.6 o superior.
- La librería `psycopg2-binary` instalada (`pip install psycopg2-binary`).
- Acceso de red y credenciales para ambas bases de datos (OLTP y OLAP).
- Las funciones y tablas correspondientes deben existir en las bases de datos, según los scripts SQL del proyecto.

## Configuración

El script se configura mediante las siguientes variables de entorno. Asegúrate de definirlas en el entorno donde se ejecutará el script:

**Base de Datos OLTP (Origen):**
- `OLTP_DB_HOST`: Host de la base de datos (ej. `localhost` o una IP).
- `OLTP_DB_PORT`: Puerto de la base de datos (ej. `5432`).
- `OLTP_DB_NAME`: Nombre de la base de datos.
- `OLTP_DB_USER`: Usuario con permisos de lectura.
- `OLTP_DB_PASSWORD`: Contraseña del usuario.

**Base de Datos OLAP (Destino):**
- `OLAP_DB_HOST`: Host de la base de datos.
- `OLAP_DB_PORT`: Puerto de la base de datos (ej. `5433`).
- `OLAP_DB_NAME`: Nombre de la base de datos.
- `OLAP_DB_USER`: Usuario con permisos para ejecutar las funciones de carga.
- `OLAP_DB_PASSWORD`: Contraseña del usuario.

## Funcionamiento

1.  **Obtener Última Ejecución**: El script lee el archivo `last_run.txt` para saber desde qué fecha y hora debe empezar a buscar transacciones. Si el archivo no existe, por defecto busca las transacciones de los últimos 7 días.
2.  **Extraer Datos (Extract)**: Se conecta a la base de datos OLTP y extrae todas las transacciones de tipo `VENTA` y `ENTRADA_MERCANCIA` que sean más recientes que la última ejecución.
3.  **Cargar Datos (Load)**: Se conecta a la base de datos OLAP y, para cada transacción extraída, invoca los procedimientos almacenados correspondientes:
    - `actualizar_costo_promedio()`: Para las entradas de mercancía.
    - `actualizar_stock_venta()`: Para las ventas.
    - `calcular_precio_sugerido()`: Para recalcular precios después de una entrada.
4.  **Refrescar Vistas**: Una vez cargados todos los datos, ejecuta la función `refrescar_vistas_materializadas()` en la base de datos OLAP para que los cambios se reflejen en los análisis y dashboards.
5.  **Guardar Estado**: Si todo el proceso fue exitoso, guarda el timestamp actual en el archivo `last_run.txt` para la próxima ejecución.

## Ejecución

Para ejecutar el script manualmente, navega al directorio `scripts` y ejecuta:

```bash
# Exportar las variables de entorno (ejemplo)
export OLTP_DB_USER=mi_usuario_oltp
export OLTP_DB_PASSWORD=mi_clave_secreta
export OLAP_DB_USER=mi_usuario_olap
export OLAP_DB_PASSWORD=mi_otra_clave

# Ejecutar el script
python etl.py
```

Para una ejecución automatizada, configura un `cronjob` que ejecute este comando con la periodicidad deseada (por ejemplo, todos los domingos a las 2 AM):

```cron
0 2 * * 0 /usr/bin/python /ruta/completa/a/pymes/scripts/etl.py >> /var/log/etl.log 2>&1
```
