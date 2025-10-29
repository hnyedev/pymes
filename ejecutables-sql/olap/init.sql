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
-- Name: actualizar_costo_promedio(character varying, integer, numeric); Type: FUNCTION; Schema: public; O
wner: superu                                                                                              
--                                                                                                        
                                                                                                          
CREATE FUNCTION public.actualizar_costo_promedio(p_producto_id character varying, p_cantidad_nueva integer
, p_costo_unitario_nuevo numeric) RETURNS void                                                            
    LANGUAGE plpgsql                                                                                      
    AS $$                                                                                                 
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
$$;                                                                                                       
                                                                                                          
                                                                                                          
ALTER FUNCTION public.actualizar_costo_promedio(p_producto_id character varying, p_cantidad_nueva integer,
 p_costo_unitario_nuevo numeric) OWNER TO superu;                                                         
                                                                                                          
--                                                                                                        
-- Name: FUNCTION actualizar_costo_promedio(p_producto_id character varying, p_cantidad_nueva integer, p_c
osto_unitario_nuevo numeric); Type: COMMENT; Schema: public; Owner: superu                                
--                                                                                                        
                                                                                                          
COMMENT ON FUNCTION public.actualizar_costo_promedio(p_producto_id character varying, p_cantidad_nueva int
eger, p_costo_unitario_nuevo numeric) IS 'Actualiza el CPPM cuando se recibe una entrada de mercancía (eve
nto)';                                                                                                    
                                                                                                          
                                                                                                          
--                                                                                                        
-- Name: actualizar_stock_venta(character varying, integer); Type: FUNCTION; Schema: public; Owner: superu
--                                                                                                        
                                                                                                          
CREATE FUNCTION public.actualizar_stock_venta(p_producto_id character varying, p_cantidad_vendida integer)
 RETURNS void                                                                                             
    LANGUAGE plpgsql                                                                                      
    AS $$                                                                                                 
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
$$;                                                                                                       
                                                                                                          
                                                                                                          
ALTER FUNCTION public.actualizar_stock_venta(p_producto_id character varying, p_cantidad_vendida integer) 
OWNER TO superu;                                                                                          
                                                                                                          
--                                                                                                        
-- Name: FUNCTION actualizar_stock_venta(p_producto_id character varying, p_cantidad_vendida integer); Typ
e: COMMENT; Schema: public; Owner: superu                                                                 
--                                                                                                        
                                                                                                          
COMMENT ON FUNCTION public.actualizar_stock_venta(p_producto_id character varying, p_cantidad_vendida inte
ger) IS 'Actualiza el stock cuando se consume un evento de venta';                                        
                                                                                                          
                                                                                                          
--                                                                                                        
-- Name: calcular_precio_sugerido(character varying, numeric); Type: FUNCTION; Schema: public; Owner: supe
ru                                                                                                        
--                                                                                                        
                                                                                                          
CREATE FUNCTION public.calcular_precio_sugerido(p_producto_id character varying, p_margen_porcentual numer
ic DEFAULT 40.00) RETURNS void                                                                            
    LANGUAGE plpgsql                                                                                      
    AS $$                                                                                                 
DECLARE
