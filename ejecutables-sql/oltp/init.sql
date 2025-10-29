--                                                                                                        
-- PostgreSQL database dump                                                                               
--                                                                                                        
                                                                                                          
                                                                                                          
-- Dumped from database version 16.10 (Debian 16.10-1.pgdg13+1)                                           
-- Dumped by pg_dump version 16.10 (Debian 16.10-1.pgdg13+1)                                              
                                                                                                          
SET statement_timeout = 0;                                                                                
SET lock_timeout = 0;                                                                                     
SET idle_in_transaction_session_timeout = 0;                                                              
SET client_encoding = 'UTF8';                                                                             
SET standard_conforming_strings = on;                                                                     
SELECT pg_catalog.set_config('search_path', '', false);                                                   
SET check_function_bodies = false;                                                                        
SET xmloption = content;                                                                                  
SET client_min_messages = warning;                                                                        
SET row_security = off;                                                                                   
                                                                                                          
--                                                                                                        
-- Name: update_transaccion_total(); Type: FUNCTION; Schema: public; Owner: superu                        
--                                                                                                        
                                                                                                          
CREATE FUNCTION public.update_transaccion_total() RETURNS trigger                                         
    LANGUAGE plpgsql                                                                                      
    AS $$                                                                                                 
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
$$;                                                                                                       
                                                                                                          
                                                                                                          
ALTER FUNCTION public.update_transaccion_total() OWNER TO superu;                                         
                                                                                                          
--                                                                                                        
-- Name: update_updated_at(); Type: FUNCTION; Schema: public; Owner: superu                               
--                                                                                                        
                                                                                                          
CREATE FUNCTION public.update_updated_at() RETURNS trigger                                                
    LANGUAGE plpgsql                                                                                      
    AS $$                                                                                                 
BEGIN                                                                                                     
    NEW.updated_at = CURRENT_TIMESTAMP;                                                                   
    RETURN NEW;                                                                                           
END;                                                                                                      
$$;                                                                                                       
                                                                                                          
                                                                                                          
ALTER FUNCTION public.update_updated_at() OWNER TO superu;                                                
                                                                                                          
SET default_tablespace = '';                                                                              
                                                                                                          
SET default_table_access_method = heap;                                                                   
                                                                                                          
--                                                                                                        
-- Name: entradas_mercancia; Type: TABLE; Schema: public; Owner: superu                                   
--                                                                                                        
                                                                                                          
CREATE TABLE public.entradas_mercancia (                                                                  
    entrada_id bigint NOT NULL,                                                                           
    transaccion_id bigint NOT NULL,                                                                       
    nombre_proveedor character varying(255) NOT NULL,                                                     
    numero_factura character varying(100),                                                                
    fecha_recepcion date DEFAULT CURRENT_DATE,                                                            
    notas text,                                                                                           
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP                                      
);                                                                                                        
                                                                                                          
                                                                                                          
ALTER TABLE public.entradas_mercancia OWNER TO superu;                                                    
                                                                                                          
--                                                                                                        
-- Name: entradas_mercancia_entrada_id_seq; Type: SEQUENCE; Schema: public; Owner: superu                 
--                                                                                                        
                                                                                                          
CREATE SEQUENCE public.entradas_mercancia_entrada_id_seq                                                  
    START WITH 1                                                                                          
    INCREMENT BY 1                                                                                        
    NO MINVALUE                                                                                           
    NO MAXVALUE                                                                                           
    CACHE 1;                                                                                              
                                                                                                          
                                                                                                          
ALTER SEQUENCE public.entradas_mercancia_entrada_id_seq OWNER TO superu;                                  
                                                                                                          
--                                                                                                        
-- Name: entradas_mercancia_entrada_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: superu        
--                                                                                                        
                                                                                                          
ALTER SEQUENCE public.entradas_mercancia_entrada_id_seq OWNED BY public.entradas_mercancia.entrada_id;    
                                                                                                          
                                                                                                          
--                                                                                                        
-- Name: items_transaccion; Type: TABLE; Schema: public; Owner: superu                                    
--                                                                                                        
                                                                                                          
CREATE TABLE public.items_transaccion (                                                                   
    item_id bigint NOT NULL,                                                                              
    transaccion_id bigint NOT NULL,                                                                       
    producto_id character varying(50) NOT NULL,                                                           
    cantidad integer NOT NULL,                                                                            
    precio_unitario_venta numeric(10,2),                                                                  
    costo_unitario_compra numeric(10,2),                                                                  
    subtotal numeric(10,2) GENERATED ALWAYS AS (                                                          
CASE                                                                                                      
    WHEN (precio_unitario_venta IS NOT NULL) THEN ((cantidad)::numeric * precio_unitario_venta)           
    WHEN (costo_unitario_compra IS NOT NULL) THEN ((cantidad)::numeric * costo_unitario_compra)           
    ELSE (0)::numeric                                                                                     
END) STORED,                                                                                              
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,                                     
    CONSTRAINT chk_precio_o_costo CHECK ((((precio_unitario_venta IS NOT NULL) AND (costo_unitario_compra 
IS NULL)) OR ((precio_unitario_venta IS NULL) AND (costo_unitario_compra IS NOT NULL)))),                 
    CONSTRAINT items_transaccion_cantidad_check CHECK ((cantidad > 0))                                    
);                                                                                                        
                                                                                                          
                                                                                                          
ALTER TABLE public.items_transaccion OWNER TO superu;                                                     
                                                                                                          
--                                                                                                        
-- Name: items_transaccion_item_id_seq; Type: SEQUENCE; Schema: public; Owner: superu                     
--                                                                                                        
                                                                                                          
CREATE SEQUENCE public.items_transaccion_item_id_seq                                                      
    START WITH 1                                                                                          
    INCREMENT BY 1                                                                                        
    NO MINVALUE                                                                                           
    NO MAXVALUE                                                                                           
    CACHE 1;                                                                                              
                                                                                                          
                                                                                                          
ALTER SEQUENCE public.items_transaccion_item_id_seq OWNER TO superu;                                      
                                                                                                          
--                                                                                                        
-- Name: items_transaccion_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: superu            
--                                                                                                        
                                                                                                          
ALTER SEQUENCE public.items_transaccion_item_id_seq OWNED BY public.items_transaccion.item_id;            
                                                                                                          
                                                                                                          
--                                                                                                        
-- Name: productos_maestro; Type: TABLE; Schema: public; Owner: superu                                    
--                                                                                                        
                                                                                                          
CREATE TABLE public.productos_maestro (                                                                   
    producto_id character varying(50) NOT NULL,                                                           
    nombre_producto character varying(255) NOT NULL,                                                      
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,                                     
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP                                      
);                                                                                                        
                                                                                                          
                                                                                                          
ALTER TABLE public.productos_maestro OWNER TO superu;                                                     
                                                                                                          
--                                                                                                        
-- Name: transacciones; Type: TABLE; Schema: public; Owner: superu                                        
--                                                                                                        
                                                                                                          
CREATE TABLE public.transacciones (                                                                       
    transaccion_id bigint NOT NULL,                                                                       
    tipo_transaccion character varying(30) NOT NULL,                                                      
    fecha_hora timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,                            
    estado character varying(20) DEFAULT 'COMPLETADA'::character varying NOT NULL,                        
    total_bruto numeric(10,2) DEFAULT 0.00 NOT NULL,                                                      
    notas text,                                                                                           
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,                                     
    CONSTRAINT transacciones_estado_check CHECK (((estado)::text = ANY ((ARRAY['COMPLETADA'::character var
ying, 'CANCELADA'::character varying])::text[]))),                                                        
    CONSTRAINT transacciones_tipo_transaccion_check CHECK (((tipo_transaccion)::text = ANY ((ARRAY['VENTA'
::character varying, 'ENTRADA_MERCANCIA'::character varying, 'DEVOLUCION'::character varying])::text[]))) 
);                                                                                                        
                                                                                                          
                                                                                                          
ALTER TABLE public.transacciones OWNER TO superu;                                                         
                                                                                                          
--                                                                                                        
-- Name: transacciones_transaccion_id_seq; Type: SEQUENCE; Schema: public; Owner: superu                  
--                                                                                                        
                                                                                                          
CREATE SEQUENCE public.transacciones_transaccion_id_seq                                                   
    START WITH 1                                                                                          
    INCREMENT BY 1                                                                                        
    NO MINVALUE                                                                                           
    NO MAXVALUE                                                                                           
    CACHE 1;                                                                                              
                                                                                                          
                                                                                                          
ALTER SEQUENCE public.transacciones_transaccion_id_seq OWNER TO superu;                                   
                                                                                                          
--                                                                                                        
-- Name: transacciones_transaccion_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: superu         
--                                                                                                        
                                                                                                          
ALTER SEQUENCE public.transacciones_transaccion_id_seq OWNED BY public.transacciones.transaccion_id;      
                                                                                                          
                                                                                                          
--                                                                                                        
-- Name: entradas_mercancia entrada_id; Type: DEFAULT; Schema: public; Owner: superu                      
--                                                                                                        
                                                                                                          
ALTER TABLE ONLY public.entradas_mercancia ALTER COLUMN entrada_id SET DEFAULT nextval('public.entradas_me
rcancia_entrada_id_seq'::regclass);                                                                       
                                                                                                          
                                                                                                          
--                                                                                                        
-- Name: items_transaccion item_id; Type: DEFAULT; Schema: public; Owner: superu                          
--                                                                                                        
                                                                                                          
ALTER TABLE ONLY public.items_transaccion ALTER COLUMN item_id SET DEFAULT nextval('public.items_transacci
on_item_id_seq'::regclass);                                                                               
                                                                                                          
                                                                                                          
--                                                                                                        
-- Name: transacciones transaccion_id; Type: DEFAULT; Schema: public; Owner: superu                       
--                                                                                                        
                                                                                                          
ALTER TABLE ONLY public.transacciones ALTER COLUMN transaccion_id SET DEFAULT nextval('public.transaccione
s_transaccion_id_seq'::regclass);                                                                         
                                                                                                          
                                                                                                          
--                                                                                                        
-- Name: entradas_mercancia entradas_mercancia_pkey; Type: CONSTRAINT; Schema: public; Owner: superu      
--                                                                                                        
                                                                                                          
ALTER TABLE ONLY public.entradas_mercancia                                                                
    ADD CONSTRAINT entradas_mercancia_pkey PRIMARY KEY (entrada_id);                                      
                                                                                                          
                                                                                                          
--                                                                                                        
-- Name: entradas_mercancia entradas_mercancia_transaccion_id_key; Type: CONSTRAINT; Schema: public; Owner
: superu                                                                                                  
--                                                                                                        
                                                                                                          
ALTER TABLE ONLY public.entradas_mercancia                                                                
    ADD CONSTRAINT entradas_mercancia_transaccion_id_key UNIQUE (transaccion_id);                         
                                                                                                          
                                                                                                          
--                                                                                                        
-- Name: items_transaccion items_transaccion_pkey; Type: CONSTRAINT; Schema: public; Owner: superu        
--                                                                                                        
                                                                                                          
ALTER TABLE ONLY public.items_transaccion                                                                 
    ADD CONSTRAINT items_transaccion_pkey PRIMARY KEY (item_id);                                          
                                                                                                          
                                                                                                          
--                                                                                                        
-- Name: productos_maestro productos_maestro_pkey; Type: CONSTRAINT; Schema: public; Owner: superu        
--                                                                                                        
                                                                                                          
ALTER TABLE ONLY public.productos_maestro                                                                 
    ADD CONSTRAINT productos_maestro_pkey PRIMARY KEY (producto_id);                                      
                                                                                                          
                                                                                                          
--                                                                                                        
-- Name: transacciones transacciones_pkey; Type: CONSTRAINT; Schema: public; Owner: superu                
--                                                                                                        
                                                                                                          
ALTER TABLE ONLY public.transacciones                                                                     
    ADD CONSTRAINT transacciones_pkey PRIMARY KEY (transaccion_id);                                       
                                                                                                          
                                                                                                          
--                                                                                                        
-- Name: idx_entradas_fecha; Type: INDEX; Schema: public; Owner: superu                                   
--                                                                                                        
                                                                                                          
CREATE INDEX idx_entradas_fecha ON public.entradas_mercancia USING btree (fecha_recepcion DESC);          
                                                                                                          
                                                                                                          
--                                                                                                        
-- Name: idx_entradas_proveedor; Type: INDEX; Schema: public; Owner: superu                               
--                                                                                                        
                                                                                                          
CREATE INDEX idx_entradas_proveedor ON public.entradas_mercancia USING btree (nombre_proveedor);          
                                                                                                          
                                                                                                          
--                                                                                                        
-- Name: idx_items_lookup; Type: INDEX; Schema: public; Owner: superu                                     
--                                                                                                        
                                                                                                          
CREATE INDEX idx_items_lookup ON public.items_transaccion USING btree (transaccion_id, producto_id);      
                                                                                                          
                                                                                                          
--                                                                                                        
-- Name: idx_items_producto_id; Type: INDEX; Schema: public; Owner: superu                                
--                                                                                                        
                                                                                                          
CREATE INDEX idx_items_producto_id ON public.items_transaccion USING btree (producto_id);                 
                                                                                                          
                                                                                                          
--                                                                                                        
-- Name: idx_items_transaccion_id; Type: INDEX; Schema: public; Owner: superu                             
--                                                                                                        
                                                                                                          
CREATE INDEX idx_items_transaccion_id ON public.items_transaccion USING btree (transaccion_id);           
                                                                                                          
                                                                                                          
--                                                                                                        
-- Name: idx_productos_nombre; Type: INDEX; Schema: public; Owner: superu                                 
--                                                                                                        
                                                                                                          
CREATE INDEX idx_productos_nombre ON public.productos_maestro USING btree (nombre_producto);              
                                                                                                          
                                                                                                          
--                                                                                                        
-- Name: idx_transacciones_estado; Type: INDEX; Schema: public; Owner: superu                             
--                                                                                                        
                                                                                                          
CREATE INDEX idx_transacciones_estado ON public.transacciones USING btree (estado);                       
                                                                                                          
                                                                                                          
--                                                                                                        
-- Name: idx_transacciones_fecha; Type: INDEX; Schema: public; Owner: superu                              
--                                                                                                        
                                                                                                          
CREATE INDEX idx_transacciones_fecha ON public.transacciones USING btree (fecha_hora DESC);               
                                                                                                          
                                                                                                          
--                                                                                                        
-- Name: idx_transacciones_tipo; Type: INDEX; Schema: public; Owner: superu                               
--                                                                                                        
                                                                                                          
CREATE INDEX idx_transacciones_tipo ON public.transacciones USING btree (tipo_transaccion);               
                                                                                                          
                                                                                                          
--                                                                                                        
-- Name: items_transaccion trg_items_update_total; Type: TRIGGER; Schema: public; Owner: superu           
--                                                                                                        
                                                                                                          
CREATE TRIGGER trg_items_update_total AFTER INSERT OR UPDATE ON public.items_transaccion FOR EACH ROW EXEC
UTE FUNCTION public.update_transaccion_total();                                                           
                                                                                                          
                                                                                                          
--                                                                                                        
-- Name: productos_maestro trg_productos_maestro_updated_at; Type: TRIGGER; Schema: public; Owner: superu 
--                                                                                                        
                                                                                                          
CREATE TRIGGER trg_productos_maestro_updated_at BEFORE UPDATE ON public.productos_maestro FOR EACH ROW EXE
CUTE FUNCTION public.update_updated_at();                                                                 
                                                                                                          
                                                                                                          
--                                                                                                        
-- Name: entradas_mercancia fk_entrada_transaccion; Type: FK CONSTRAINT; Schema: public; Owner: superu    
--                                                                                                        
                                                                                                          
ALTER TABLE ONLY public.entradas_mercancia                                                                
    ADD CONSTRAINT fk_entrada_transaccion FOREIGN KEY (transaccion_id) REFERENCES public.transacciones(tra
nsaccion_id) ON DELETE CASCADE;                                                                           
                                                                                                          
                                                                                                          
--                                                                                                        
-- Name: items_transaccion fk_items_producto; Type: FK CONSTRAINT; Schema: public; Owner: superu          
--                                                                                                        
                                                                                                          
ALTER TABLE ONLY public.items_transaccion                                                                 
    ADD CONSTRAINT fk_items_producto FOREIGN KEY (producto_id) REFERENCES public.productos_maestro(product
o_id) ON DELETE RESTRICT;                                                                                 
                                                                                                          
                                                                                                          
--                                                                                                        
-- Name: items_transaccion fk_items_transaccion; Type: FK CONSTRAINT; Schema: public; Owner: superu       
--                                                                                                        
                                                                                                          
ALTER TABLE ONLY public.items_transaccion                                                                 
    ADD CONSTRAINT fk_items_transaccion FOREIGN KEY (transaccion_id) REFERENCES public.transacciones(trans
accion_id) ON DELETE CASCADE;                                                                             
                                                                                                          
                                                                                                          
--                                                                                                        
-- PostgreSQL database dump complete                                                                      
--                                                                                                        
                                                                                                          
