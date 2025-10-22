-- ============================================
-- TABLA: categorias
-- Proposito: Dimension analitica para clasificacion de productos
-- ============================================
CREATE TABLE categorias (
    categoria_id VARCHAR(50) PRIMARY KEY,
    nombre_categoria VARCHAR(255) NOT NULL UNIQUE,
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_categorias_nombre ON categorias(nombre_categoria);

-- TABLA: productos
-- Proposito: Fuente de verdad del stock actual y calculos de costos/precios #single source of truth 
-- ============================================
CREATE TABLE productos (
    producto_id VARCHAR(50) PRIMARY KEY,
    nombre_producto VARCHAR(255) NOT NULL,
    categoria VARCHAR(50),
    stock_actual INTEGER NOT NULL DEFAULT 0 CHECK (stock_actual >= 0),
    costo_promedio DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    precio_venta_sugerido DECIMAL(10, 2),
    precio_venta_final DECIMAL(10, 2) NOT NULL,
    ultima_entrada_fecha DATE,
    ultima_venta_fecha DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Relacion con categorias
    CONSTRAINT fk_productos_categoria FOREIGN KEY (categoria) 
        REFERENCES categorias(categoria_id) ON DELETE SET NULL,
    
    -- Validaciones de negocio
    CONSTRAINT chk_costo_promedio_positivo CHECK (costo_promedio >= 0),
    CONSTRAINT chk_precios_positivos CHECK (precio_venta_final > 0)
);

CREATE INDEX idx_productos_categoria ON productos(categoria);
CREATE INDEX idx_productos_stock ON productos(stock_actual);
CREATE INDEX idx_productos_ultima_venta ON productos(ultima_venta_fecha DESC);
CREATE INDEX idx_productos_ultima_entrada ON productos(ultima_entrada_fecha DESC);


-- indice compuesto para analisis de rotacion
CREATE INDEX idx_productos_rotacion ON productos(ultima_venta_fecha, stock_actual);

-- ============================================
-- VISTAS MATERIALIZADAS PARA SUPERSET
-- ============================================

-- ============================================
-- VISTA MATERIALIZADA: mv_productos_estancados
-- Insight I2: Rotacion de Inventario y Alerta de Estancamiento
-- Proposito: Identificar productos que no se mueven
CREATE MATERIALIZED VIEW mv_productos_estancados AS
SELECT 
    p.producto_id,
    p.nombre_producto,
    c.nombre_categoria,
    p.stock_actual,
    p.ultima_venta_fecha,
    CASE 
        WHEN p.ultima_venta_fecha IS NULL THEN 999
        ELSE CURRENT_DATE - p.ultima_venta_fecha
    END AS dias_sin_venta,
    p.costo_promedio,
    (p.stock_actual * p.costo_promedio) AS valor_inventario_estancado,
    CASE 
        WHEN p.ultima_venta_fecha IS NULL THEN 'SIN_VENTAS'
        WHEN CURRENT_DATE - p.ultima_venta_fecha > 90 THEN 'CRITICO'
        WHEN CURRENT_DATE - p.ultima_venta_fecha > 60 THEN 'ALERTA'
        WHEN CURRENT_DATE - p.ultima_venta_fecha > 30 THEN 'ATENCION'
        ELSE 'NORMAL'
    END AS estado_rotacion
FROM productos p
LEFT JOIN categorias c ON p.categoria = c.categoria_id
WHERE p.stock_actual > 0;

-- Índices en la vista materializada
CREATE UNIQUE INDEX idx_mv_estancados_producto_id ON mv_productos_estancados(producto_id);
CREATE INDEX idx_mv_estancados_estado ON mv_productos_estancados(estado_rotacion);
CREATE INDEX idx_mv_estancados_dias ON mv_productos_estancados(dias_sin_venta DESC);

-- ============================================
-- VISTA MATERIALIZADA: mv_analisis_pricing
-- Insight I4: Precio Sugerido vs Precio Final
-- Propósito: Análisis de estrategia de precios
-- ============================================
CREATE MATERIALIZED VIEW mv_analisis_pricing AS
SELECT 
    p.producto_id,
    p.nombre_producto,
    c.nombre_categoria,
    p.costo_promedio,
    p.precio_venta_sugerido,
    p.precio_venta_final,
    ROUND(((p.precio_venta_final - p.costo_promedio) / NULLIF(p.costo_promedio, 0)) * 100, 2) AS margen_porcentual_actual,
    CASE 
        WHEN p.precio_venta_sugerido IS NOT NULL THEN
            ROUND(((p.precio_venta_sugerido - p.costo_promedio) / NULLIF(p.costo_promedio, 0)) * 100, 2)
        ELSE NULL
    END AS margen_porcentual_sugerido,
    CASE 
        WHEN p.precio_venta_sugerido IS NOT NULL THEN
            p.precio_venta_final - p.precio_venta_sugerido
        ELSE NULL
    END AS diferencia_precio,
    p.stock_actual,
    (p.stock_actual * p.costo_promedio) AS valor_inventario_costo,
    (p.stock_actual * p.precio_venta_final) AS valor_inventario_venta
FROM productos p
LEFT JOIN categorias c ON p.categoria = c.categoria_id;

CREATE UNIQUE INDEX idx_mv_pricing_producto_id ON mv_analisis_pricing(producto_id);
CREATE INDEX idx_mv_pricing_margen ON mv_analisis_pricing(margen_porcentual_actual);
CREATE INDEX idx_mv_pricing_categoria ON mv_analisis_pricing(nombre_categoria);

-- ============================================
-- VISTA SIMPLE: v_resumen_inventario
-- Propósito: Dashboard general de inventario
-- ============================================
CREATE VIEW v_resumen_inventario AS
SELECT 
    c.nombre_categoria,
    COUNT(p.producto_id) AS total_productos,
    SUM(p.stock_actual) AS unidades_totales,
    SUM(p.stock_actual * p.costo_promedio) AS valor_total_costo,
    SUM(p.stock_actual * p.precio_venta_final) AS valor_total_venta,
    ROUND(AVG((p.precio_venta_final - p.costo_promedio) / NULLIF(p.costo_promedio, 0)) * 100, 2) AS margen_promedio_porcentual,
    COUNT(CASE WHEN p.stock_actual = 0 THEN 1 END) AS productos_sin_stock,
    COUNT(CASE WHEN p.stock_actual > 0 AND (CURRENT_DATE - p.ultima_venta_fecha > 60 OR p.ultima_venta_fecha IS NULL) THEN 1 END) AS productos_estancados
FROM productos p
LEFT JOIN categorias c ON p.categoria = c.categoria_id
GROUP BY c.nombre_categoria;


CREATE VIEW v_productos_bajo_stock AS
SELECT 
    p.producto_id,
    p.nombre_producto,
    c.nombre_categoria,
    p.stock_actual,
    p.ultima_entrada_fecha,
    p.ultima_venta_fecha,
    CASE 
        WHEN p.stock_actual = 0 THEN 'SIN_STOCK'
        WHEN p.stock_actual <= 5 THEN 'CRITICO'
        WHEN p.stock_actual <= 10 THEN 'BAJO'
        ELSE 'NORMAL'
    END AS nivel_alerta
FROM productos p
LEFT JOIN categorias c ON p.categoria = c.categoria_id
WHERE p.stock_actual <= 10
ORDER BY p.stock_actual ASC;