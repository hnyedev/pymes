-- ============================================
-- TABLA: productos_maestro
-- Propósito: Catálogo maestro de productos
-- ============================================
CREATE TABLE productos_maestro (
    producto_id VARCHAR(50) PRIMARY KEY,
    nombre_producto VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índice para búsquedas por nombre
CREATE INDEX idx_productos_nombre ON productos_maestro(nombre_producto);

-- ============================================
-- TABLA: transacciones
-- Propósito: Registro de ventas y entradas
-- ============================================
CREATE TABLE transacciones (
    transaccion_id BIGSERIAL PRIMARY KEY,
    tipo_transaccion VARCHAR(30) NOT NULL CHECK (tipo_transaccion IN ('VENTA', 'ENTRADA_MERCANCIA', 'DEVOLUCION')),
    fecha_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(20) NOT NULL CHECK (estado IN ('COMPLETADA', 'CANCELADA')) DEFAULT 'COMPLETADA',
    total_bruto DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    notas TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para consultas frecuentes
CREATE INDEX idx_transacciones_fecha ON transacciones(fecha_hora DESC);
CREATE INDEX idx_transacciones_tipo ON transacciones(tipo_transaccion);
CREATE INDEX idx_transacciones_estado ON transacciones(estado);

-- ============================================
-- TABLA: items_transaccion
-- Propósito: Líneas de detalle de cada transacción
-- ============================================
CREATE TABLE items_transaccion (
    item_id BIGSERIAL PRIMARY KEY,
    transaccion_id BIGINT NOT NULL,
    producto_id VARCHAR(50) NOT NULL,
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    precio_unitario_venta DECIMAL(10, 2),
    costo_unitario_compra DECIMAL(10, 2),
    subtotal DECIMAL(10, 2) GENERATED ALWAYS AS (
        CASE 
            WHEN precio_unitario_venta IS NOT NULL THEN cantidad * precio_unitario_venta
            WHEN costo_unitario_compra IS NOT NULL THEN cantidad * costo_unitario_compra
            ELSE 0
        END
    ) STORED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Relaciones
    CONSTRAINT fk_items_transaccion FOREIGN KEY (transaccion_id) 
        REFERENCES transacciones(transaccion_id) ON DELETE CASCADE,
    CONSTRAINT fk_items_producto FOREIGN KEY (producto_id) 
        REFERENCES productos_maestro(producto_id) ON DELETE RESTRICT,
    
    -- Validación de negocio
    CONSTRAINT chk_precio_o_costo CHECK (
        (precio_unitario_venta IS NOT NULL AND costo_unitario_compra IS NULL) OR
        (precio_unitario_venta IS NULL AND costo_unitario_compra IS NOT NULL)
    )
);

-- Índices para optimizar JOINs
CREATE INDEX idx_items_transaccion_id ON items_transaccion(transaccion_id);
CREATE INDEX idx_items_producto_id ON items_transaccion(producto_id);
CREATE INDEX idx_items_lookup ON items_transaccion(transaccion_id, producto_id);

-- ============================================
-- TABLA: entradas_mercancia
-- Propósito: Información adicional de compras
-- ============================================
CREATE TABLE entradas_mercancia (
    entrada_id BIGSERIAL PRIMARY KEY,
    transaccion_id BIGINT NOT NULL UNIQUE,
    nombre_proveedor VARCHAR(255) NOT NULL,
    numero_factura VARCHAR(100),
    fecha_recepcion DATE DEFAULT CURRENT_DATE,
    notas TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Relación
    CONSTRAINT fk_entrada_transaccion FOREIGN KEY (transaccion_id) 
        REFERENCES transacciones(transaccion_id) ON DELETE CASCADE
);

-- Índice para búsquedas por proveedor
CREATE INDEX idx_entradas_proveedor ON entradas_mercancia(nombre_proveedor);
CREATE INDEX idx_entradas_fecha ON entradas_mercancia(fecha_recepcion DESC);