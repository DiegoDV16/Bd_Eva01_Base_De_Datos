-- Instalador de la capa complementaria de lógica de negocio.
-- Ejecutar este archivo con Run Script (F5) desde SQL Developer o SQLcl,
-- despues de ejecutar Park_Control.sql.
-- Este instalador tambien ejecuta el trigger de control existente.
-- La bitacora es opcional; instalarla por separado con instalar_bitacora.sql.
-- Las instrucciones @@ resuelven los archivos desde esta misma carpeta.

SET SERVEROUTPUT ON SIZE UNLIMITED;

@@trigger.sql
@@package.sql
@@procedimiento.sql
@@funcion.sql
