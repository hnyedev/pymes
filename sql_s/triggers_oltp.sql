CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $BODY$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$BODY$ LANGUAGE plpgsql;

-- Trigger para la tabla productos_maestro
CREATE TRIGGER trg_productos_maestro_updated_at
    BEFORE UPDATE ON productos_maestro
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Función para actualizar total_bruto de transacción
CREATE OR REPLACE FUNCTION update_transaccion_total() --update transacción
RETURNS TRIGGER AS $BODY$
BEGIN
    UPDATE transacciones
    SET total_bruto = (
        SELECT COALESCE(SUM(subtotal), 0)
        FROM items_transaccion
        WHERE transaccion_id = NEW.transaccion_id
    )
    WHERE transaccion_id = NEW.transaccion_id;
    RETURN NEW;
END;
$BODY$ LANGUAGE plpgsql;

-- Trigger para actualizar total cuando se insertan/actualizan items
CREATE TRIGGER trg_items_update_total --create the trigger
    AFTER INSERT OR UPDATE ON items_transaccion -- after insert or update some item
    FOR EACH ROW --we call the function update transaccion
    EXECUTE FUNCTION update_transaccion_total();

    