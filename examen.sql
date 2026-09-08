------ 1.MOSTRAR LOS CLIENTES JUNTO AL TOTAL PAGADO EN EL MES ACTUAL  -----


SELECT c.cliente_id, CONCAT(c.nombre, ' ', c.apellido) AS cliente,SUM(p.monto) AS recaudo_del_mes_actual
FROM clientes c
INNER JOIN contratos co 
    ON c.cliente_id = co.id_cliente
INNER JOIN pagos p 
    ON co.id_contrato = p.id_contrato
WHERE p.estado = 'procesado'
  AND DATE_FORMAT(p.fecha_pago, '%Y-%m') = DATE_FORMAT(CURRENT_DATE, '%Y-%m')
GROUP BY c.cliente_id, c.nombre, c.apellido;


---- 2. Pagos con fecha de pago al dia actual ---------

SELECT p.id_contrato, SUM(p.monto) AS pago_total
FROM pagos p
WHERE p.estado = 'procesando'
  AND DATE(p.fecha_pago) = CURRENT_DATE
GROUP BY p.id_contrato;


---- 3. listar los clientes con mas de 2 pagos atrasados  ------
SELECT  c.cliente_id, CONCAT(c.nombre, ' ', c.apellido) AS cliente, COUNT(p.id_pago) AS pagos_atrasados
FROM clientes c
INNER JOIN contratos co 
    ON c.cliente_id = co.id_cliente
INNER JOIN pagos p 
    ON co.id_contrato = p.id_contrato
WHERE p.estado = 'atrasado'
GROUP BY c.cliente_id, c.nombre, c.apellido
HAVING COUNT(p.id_pago) > 2;


---- 4. tigger --------


DROP TRIGGER IF EXISTS actualizar_estado_pago ;

DELIMITER $$

CREATE TRIGGER actualizar_estado_pago
AFTER UPDATE ON pagos
FOR EACH ROW

        VALUES
            (NEW.estado_pago OLD.pagos, NEW.estado, 'CAMBIO_ESTADO_PAGO', CURRENT_USER(), NOW());
    END IF;
END$$

DELIMITER ;



----- 5. reporte nombre del cliente su telefono y numero total propiedades arrendadas  -----------------

SELECT c.nombre as clientes , c.telefono
as telefono , count (p.id_propiedad) as total_propiedades 
from propiedades p , clientes c 
left join contratos c2 on id_propiedad = co.id_propiedad
where co.id_propiedad is not NULL 
group by cliente, telefono ;

