COMMENT ON DATABASE olap IS 'Base de datos analítica (OLAP) - Fuente de verdad del stock y plataforma para Apache Superset';

COMMENT ON TABLE categorias IS 'Dimensión analítica para clasificación de productos';
COMMENT ON TABLE productos IS 'Fuente de verdad del stock actual con costos promedio y precios';

COMMENT ON COLUMN productos.costo_promedio IS 'Costo Promedio Ponderado Móvil (CPPM) - CRÍTICO para cálculo de margen';
COMMENT ON COLUMN productos.precio_venta_sugerido IS 'Precio calculado automáticamente basado en regla de margen';
COMMENT ON COLUMN productos.precio_venta_final IS 'Precio real de venta definido por el usuario';
COMMENT ON COLUMN productos.ultima_venta_fecha IS 'Clave para identificar productos estancados';

COMMENT ON MATERIALIZED VIEW mv_productos_estancados IS 'Insight I2: Análisis de rotación de inventario y productos estancados';
COMMENT ON MATERIALIZED VIEW mv_analisis_pricing IS 'Insight I4: Comparación de precios sugeridos vs finales';

COMMENT ON FUNCTION actualizar_costo_promedio IS 'Actualiza el CPPM cuando se recibe una entrada de mercancía (evento)';
COMMENT ON FUNCTION actualizar_stock_venta IS 'Actualiza el stock cuando se consume un evento de venta';
COMMENT ON FUNCTION calcular_precio_sugerido IS 'Calcula precio sugerido basado en costo promedio y margen deseado';
COMMENT ON FUNCTION refrescar_vistas_materializadas IS 'Refresca todas las vistas materializadas - ejecutar periódicamente';

-- ============================================
-- PERMISOS (Ajustar según necesidad)
-- ============================================

-- Crear rol para el microservicio de inventario
-- CREATE ROLE inventario_service WITH LOGIN PASSWORD 'secure_password';
-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO inventario_service;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO inventario_service;
-- GRANT SELECT ON ALL MATERIALIZED VIEWS IN SCHEMA public TO inventario_service;

-- Crear rol para Apache Superset (solo lectura)
-- CREATE ROLE superset_readonly WITH LOGIN PASSWORD 'secure_password';
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO superset_readonly;
-- GRANT SELECT ON ALL VIEWS IN SCHEMA public TO superset_readonly;
-- GRANT SELECT ON ALL MATERIALIZED VIEWS IN SCHEMA public TO superset_readonly;