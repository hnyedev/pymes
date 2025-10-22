-- Función para actualizar timestamp de modificación
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $BODY$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$BODY$ LANGUAGE plpgsql;

-- Trigger para categorías
CREATE TRIGGER trg_categorias_updated_at
    BEFORE UPDATE ON categorias
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Trigger para productos
CREATE TRIGGER trg_productos_updated_at
    BEFORE UPDATE ON productos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- ============================================
-- FUNCIÓN: Actualizar Costo Promedio Ponderado Móvil (CPPM)
-- Esta función debe ser llamada por el microservicio de inventario
-- cuando consume eventos de ENTRADA_MERCANCIA
-- ============================================
CREATE OR REPLACE FUNCTION actualizar_costo_promedio(
    p_producto_id VARCHAR(50),
    p_cantidad_nueva INTEGER,
    p_costo_unitario_nuevo DECIMAL(10, 2)
)
RETURNS VOID AS $BODY$
DECLARE
    v_stock_actual INTEGER;
    v_costo_promedio_actual DECIMAL(10, 2);
    v_valor_inventario_actual DECIMAL(10, 2);
    v_valor_inventario_nuevo DECIMAL(10, 2);
    v_nuevo_costo_promedio DECIMAL(10, 2);
BEGIN
    -- Obtener valores actuales
    SELECT stock_actual, costo_promedio
    INTO v_stock_actual, v_costo_promedio_actual
    FROM productos
    WHERE producto_id = p_producto_id;
    
    -- Calcular nuevo costo promedio ponderado
    v_valor_inventario_actual := v_stock_actual * v_costo_promedio_actual;
    v_valor_inventario_nuevo := p_cantidad_nueva * p_costo_unitario_nuevo;
    
    v_nuevo_costo_promedio := (v_valor_inventario_actual + v_valor_inventario_nuevo) / 
                              NULLIF((v_stock_actual + p_cantidad_nueva), 0);
    
    -- Actualizar producto
    UPDATE productos
    SET 
        costo_promedio = COALESCE(v_nuevo_costo_promedio, p_costo_unitario_nuevo),
        stock_actual = stock_actual + p_cantidad_nueva,
        ultima_entrada_fecha = CURRENT_DATE
    WHERE producto_id = p_producto_id;
END;
$BODY$ LANGUAGE plpgsql;

-- ============================================
-- FUNCIÓN: Actualizar Stock por Venta
-- Llamada por el microservicio cuando consume eventos de VENTA
-- ============================================
CREATE OR REPLACE FUNCTION actualizar_stock_venta(
    p_producto_id VARCHAR(50),
    p_cantidad_vendida INTEGER
)
RETURNS VOID AS $BODY$
BEGIN
    UPDATE productos
    SET 
        stock_actual = stock_actual - p_cantidad_vendida,
        ultima_venta_fecha = CURRENT_DATE
    WHERE producto_id = p_producto_id;
    
    -- Validar que no quede stock negativo
    IF (SELECT stock_actual FROM productos WHERE producto_id = p_producto_id) < 0 THEN
        RAISE EXCEPTION 'Stock insuficiente para el producto %', p_producto_id;
    END IF;
END;
$BODY$ LANGUAGE plpgsql;

-- ============================================
-- FUNCIÓN: Calcular Precio Sugerido
-- Aplica regla de margen (ej. costo * 1.4 = 40% margen)
-- ============================================
CREATE OR REPLACE FUNCTION calcular_precio_sugerido(
    p_producto_id VARCHAR(50),
    p_margen_porcentual DECIMAL(5, 2) DEFAULT 40.00
)
RETURNS VOID AS $BODY$
DECLARE
    v_costo_promedio DECIMAL(10, 2);
    v_precio_sugerido DECIMAL(10, 2);
BEGIN
    SELECT costo_promedio INTO v_costo_promedio
    FROM productos
    WHERE producto_id = p_producto_id;
    
    v_precio_sugerido := v_costo_promedio * (1 + (p_margen_porcentual / 100));
    
    UPDATE productos
    SET precio_venta_sugerido = ROUND(v_precio_sugerido, 2)
    WHERE producto_id = p_producto_id;
END;
$BODY$ LANGUAGE plpgsql;

-- ============================================
-- FUNCIÓN: Refrescar Vistas Materializadas
-- Debe ejecutarse periódicamente (cronjob o evento programado)
-- ============================================
CREATE OR REPLACE FUNCTION refrescar_vistas_materializadas()
RETURNS VOID AS $BODY$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_productos_estancados;
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_analisis_pricing;
    
    RAISE NOTICE 'Vistas materializadas actualizadas correctamente';
END;
$BODY$ LANGUAGE plpgsql;