--1.	Â àíîíèìíîì PL/SQL áëîêå ðàñïå÷àòàòü âñå ïèôàãîðîâû ÷èñëà, 
--ìåíüøèå 25 (äëÿ ïå÷àòè èñïîëüçîâàòü ïàêåò dbms_output, ïðîöåäóðó put_line).

declare
  max_count int := 25;
begin
  for i in 1..max_count loop
    for j in i..max_count loop
      for k in j..max_count loop
        if i*i + j*j = k*k then
          dbms_output.put_line(i || ' ' || j || ' ' || k);
        end if;
      end loop;
    end loop;
  end loop;
end;
/

--2.	Ïåðåäåëàòü ïðåäûäóùèé ïðèìåð, ÷òîáû äëÿ îïðåäåëåíèÿ, ÷òî 3 ÷èñëà ïèôàãîðîâû èñïîëüçîâàëàñü ôóíêöèÿ.
create or replace function fn_check_numbers(
  p_A in int,
  p_B in int,
  p_C in int
) return boolean
is 
begin
  return p_A*p_A + p_B*p_B = p_C*p_C;
end;
/


declare
  max_count int := 25;
begin
  for i in 1..max_count loop
    for j in i..max_count loop
      for k in j..max_count loop
        if fn_check_numbers(i, j, k) then
          dbms_output.put_line(i || ' ' || j || ' ' || k);
        end if;
      end loop;
    end loop;
  end loop;
end;
/

--3.	Íàïèñàòü õðàíèìóþ ïðîöåäóðó, êîòîðîé ïåðåäàåòñÿ ID ñîòðóäíèêà è êîòîðàÿ óâåëè÷èâàåò åìó çàðïëàòó íà 10%, 
--åñëè â 2000 ãîäó ó ñîòðóäíèêà áûëè ïðîäàæè. Èñïîëüçîâàòü âûáîðêó 
--êîëè÷åñòâà çàêàçîâ çà 2000 ãîä â ïåðåìåííóþ. À çàòåì, åñëè ïåðåìåííàÿ áîëüøå 0, âûïîëíèòü update äàííûõ.
create or replace 
procedure pr_increase_salary(
  p_employee_id in employees.employee_id%type
) is
v_count_orders int;
begin
    select  count(o.order_id)
      into  v_count_orders
      from  orders o
      where o.sales_rep_id = p_employee_id and
            date'2000-01-01' <= o.order_date and o.order_date < date'2001-01-01';
    if v_count_orders > 0 then
      update employees e
        set e.salary = e.salary * 1.1
      where e.employee_id = p_employee_id;
      dbms_output.put_line('Îáíîâëåíèå ïðîøëî óñïåøíî');
    else
      dbms_output.put_line('Çàïèñåé ñ òàêìè id íå íàéäåíî');
    end if;
end;
/

declare
  main_id int:= 155;
begin
  pr_increase_salary(main_id);
end;
  
--  4.	Ïðîâåðèòü êîððåêòíîñòü äàííûõ î çàêàçàõ, à èìåííî, ÷òî ïîëå 
--  ORDER_TOTAL ðàâíî ñóììå UNIT_PRICE * QUANTITY ïî ïîçèöèÿì êàæäîãî çàêàçà. 
--  Äëÿ ýòîãî ñîçäàòü õðàíèìóþ ïðîöåäóðó, â êîòîðîé áóäåò â öèêëå for ïðîõîä ïî 
--  âñåì çàêàçàì, äàëåå ïî êîíêðåòíîìó çàêàçó îòäåëüíûì select-çàïðîñîì áóäåò 
--  âûáèðàòüñÿ ñóììà ïî ïîçèöèÿì äàííîãî çàêàçà è ñðàâíèâàòüñÿ ñ ORDER_TOTAL.
--  Äëÿ «íåêîððåêòíûõ» çàêàçîâ ðàñïå÷àòàòü êîä çàêàçà, 
--  äàòó çàêàçà, çàêàç÷èêà è ìåíåäæåðà.
create or replace
procedure pr_check_order_total
is
  v_order_total orders.order_total%type;
  v_actual_price number;
begin
  for i_order in (
    select *
      from orders
  ) loop
    v_order_total := i_order.order_total;
    select  sum(oi.unit_price * oi.quantity)
      into v_actual_price
      from  order_items oi
      where oi.order_id = i_order.order_id;
    if v_actual_price <> v_order_total then
      dbms_output.put_line(i_order.order_id || ' ' || i_order.order_date || ' ' || i_order.customer_id || ' ' || i_order.sales_rep_id);
    end if;
  end loop;        
end;

--5.	Ïåðåïèñàòü ïðåäûäóùåå çàäàíèå ñ èñïîëüçîâàíèåì ÿâíîãî êóðñîðà.
create or replace
procedure pr_check_order_total_cursor
is
  cursor cur is
    select  o.order_id,
            oi.actual_price,
            o.order_total,
            o.customer_id,
            o.order_date,
            o.sales_rep_id
      from  orders o
            inner join (select  sum(oi.unit_price * oi.quantity) as actual_price,
                          oi.order_id
                    from  order_items oi
                    group by oi.order_id
            ) oi on
              oi.order_id = o.order_id;        
  v_order cur%rowtype;
begin
  open cur;
  loop
    fetch cur into v_order;
    exit when cur%notfound;
    if v_order.order_total <> v_order.actual_price then
      dbms_output.put_line(v_order.order_id || ' ' || v_order.order_date || ' ' || v_order.customer_id || ' ' || v_order.sales_rep_id);
    end if;
  end loop;        
end;

--6.	Íàïèñàòü ôóíêöèþ, â êîòîðîé áóäåò ñîçäàí òåñòîâûé êëèåíò, 
--êîòîðîìó áóäåò ñäåëàí çàêàç íà òåêóùóþ äàòó èç îäíîé ïîçèöèè êàæäîãî
--òîâàðà íà ñêëàäå. Èìÿ òåñòîâîãî êëèåíòà è ID ñêëàäà ïåðåäàþòñÿ â 
--êà÷åñòâå ïàðàìåòðîâ. Ôóíêöèÿ âîçâðàùàåò ID ñîçäàííîãî êëèåíòà.
create or replace
function fn_create_test_client(
    p_first_name in customers.cust_first_name%type,
    p_last_name in customers.cust_last_name%type,
    p_warehouse_id in warehouses.warehouse_id%type
) return customers.customer_id%type
is 
  v_customer_id customers.customer_id%type;
  v_order_id orders.order_id%type;
  v_line_item_id order_items.line_item_id%type := 1;
  v_order_total orders.order_total%type := 0;
begin
  insert into customers (cust_first_name, cust_last_name)
    values (p_first_name, p_last_name)
    returning customer_id into v_customer_id;
  insert into orders (order_date, customer_id)
    values (sysdate, v_customer_id)
    returning order_id into v_order_id;
    
  for i_product in (
    select pi.*
      from  inventories inv
            inner join product_information pi on 
              pi.product_id = inv.product_id
      where inv.warehouse_id = p_warehouse_id and
            inv.quantity_on_hand > 0
  ) loop
    insert into order_items (order_id, line_item_id, product_id, unit_price, quantity)
      values (v_order_id, v_line_item_id, i_product.product_id, i_product.list_price, 1);
    v_line_item_id := v_line_item_id + 1;
    v_order_total := v_order_total + i_product.list_price;
  end loop;
  update  orders 
      set  order_total = v_order_total
    where order_id = v_order_id;
  return v_customer_id;
end;
/

declare
  begin
    dbms_output.put_line(fn_create_test_client('alex', 'Bakulin', 4));
  end;
/

--7.	Äîáàâèòü â ïðåäûäóùóþ ôóíêöèþ ïðîâåðêó íà ñóùåñòâîâàíèå ñêëàäà ñ 
--ïåðåäàííûì ID. Äëÿ ýòîãî âûáðàòü ñêëàä â ïåðåìåííóþ òèïà «çàïèñü î ñêëàäå» è
--ïåðåõâàòèòü èñêëþ÷åíèå no_data_found, åñëè îíî âîçíèêíåò. 
--Â îáðàáîò÷èêå èñêëþ÷åíèÿ âûéòè èç ôóíêöèè, âåðíóâ null.
create or replace
function fn_create_test_client_remake(
    p_first_name in customers.cust_first_name%type,
    p_last_name in customers.cust_last_name%type,
    p_warehouse_id in warehouses.warehouse_id%type
) return customers.customer_id%type
is 
  v_customer_id customers.customer_id%type;
  v_order_id orders.order_id%type;
  v_line_item_id order_items.line_item_id%type := 1;
  v_order_total orders.order_total%type := 0;
  v_warehouse warehouses%rowtype;
begin
  begin
    select w.* into v_warehouse
      from warehouses w
      where w.warehouse_id = p_warehouse_id;
    exception
      when no_data_found
      then return null;
  end;
  insert into customers (cust_first_name, cust_last_name)
    values (p_first_name, p_last_name)
    returning customer_id into v_customer_id;
  insert into orders (order_date, customer_id)
    values (sysdate, v_customer_id)
    returning order_id into v_order_id;
    
  for i_product in (
    select pi.*
      from  inventories inv
            inner join product_information pi on 
              pi.product_id = inv.product_id
      where inv.warehouse_id = p_warehouse_id and
            inv.quantity_on_hand > 0
  ) loop
    insert into order_items (order_id, line_item_id, product_id, unit_price, quantity)
      values (v_order_id, v_line_item_id, i_product.product_id, i_product.list_price, 1);
    v_line_item_id := v_line_item_id + 1;
    v_order_total := v_order_total + i_product.list_price;
  end loop;
  update  orders 
      set  order_total = v_order_total
    where order_id = v_order_id;
  return v_customer_id;
end;
/

declare
  begin
    dbms_output.put_line(fn_create_test_client_remake('alex', 'Bakulin', 23232323));
  end;
/
--8.	Íàïèñàííûå ïðîöåäóðû è ôóíêöèè îáúåäèíèòü â ïàêåò FIRST_PACKAGE.
create or replace
package first_package as
  function fn_check_numbers(
    p_A in int,
    p_B in int,
    p_C in int
  ) return boolean;
  procedure pr_increase_salary(
    p_employee_id in employees.employee_id%type
  );
  procedure pr_check_order_total;
  procedure pr_check_order_total_cursor;
  function fn_create_test_client(
    p_first_name in customers.cust_first_name%type,
    p_last_name in customers.cust_last_name%type,
    p_warehouse_id in warehouses.warehouse_id%type
  ) return customers.customer_id%type;
  function fn_create_test_client_remake(
    p_first_name in customers.cust_first_name%type,
    p_last_name in customers.cust_last_name%type,
    p_warehouse_id in warehouses.warehouse_id%type
  ) return customers.customer_id%type;
end first_package;
/
create or replace package body first_package  as


  function fn_check_numbers(
    p_A in int,
    p_B in int,
    p_C in int
    ) return boolean
    is 
    begin
      return p_A*p_A + p_B*p_B = p_C*p_C;
    end;
  
  
  procedure pr_increase_salary(
    p_employee_id in employees.employee_id%type
    ) is
    v_count_orders int;
    begin
        select  count(o.order_id)
          into  v_count_orders
          from  orders o
          where o.sales_rep_id = p_employee_id and
                date'2000-01-01' <= o.order_date and o.order_date < date'2001-01-01';
        if v_count_orders > 0 then
          update employees e
            set e.salary = e.salary * 1.1
          where e.employee_id = p_employee_id;
          dbms_output.put_line('Îáíîâëåíèå ïðîøëî óñïåøíî');
        else
          dbms_output.put_line('Çàïèñåé ñ òàêìè id íå íàéäåíî');
        end if;
    end;
  
  procedure pr_check_order_total
    is
      v_order_total orders.order_total%type;
      v_actual_price number;
    begin
      for i_order in (
        select *
          from orders
      ) loop
        v_order_total := i_order.order_total;
        select  sum(oi.unit_price * oi.quantity)
          into v_actual_price
          from  order_items oi
          where oi.order_id = i_order.order_id;
        if v_actual_price <> v_order_total then
          dbms_output.put_line(i_order.order_id || ' ' || i_order.order_date || ' ' || i_order.customer_id || ' ' || i_order.sales_rep_id);
        end if;
      end loop;        
    end;
  
  
  procedure pr_check_order_total_cursor
  is
    cursor cur is
      select  o.order_id,
              oi.actual_price,
              o.order_total,
              o.customer_id,
              o.order_date,
              o.sales_rep_id
        from  orders o
              inner join (select  sum(oi.unit_price * oi.quantity) as actual_price,
                            oi.order_id
                      from  order_items oi
                      group by oi.order_id
              ) oi on
                oi.order_id = o.order_id;        
    v_order cur%rowtype;
  begin
    open cur;
    loop
      fetch cur into v_order;
      exit when cur%notfound;
      if v_order.order_total <> v_order.actual_price then
        dbms_output.put_line(v_order.order_id || ' ' || v_order.order_date || ' ' || v_order.customer_id || ' ' || v_order.sales_rep_id);
      end if;
    end loop;        
  end;
  
  function fn_create_test_client(
      p_first_name in customers.cust_first_name%type,
      p_last_name in customers.cust_last_name%type,
      p_warehouse_id in warehouses.warehouse_id%type
  ) return customers.customer_id%type
  is 
    v_customer_id customers.customer_id%type;
    v_order_id orders.order_id%type;
    v_line_item_id order_items.line_item_id%type := 1;
    v_order_total orders.order_total%type := 0;
  begin
    insert into customers (cust_first_name, cust_last_name)
      values (p_first_name, p_last_name)
      returning customer_id into v_customer_id;
    insert into orders (order_date, customer_id)
      values (sysdate, v_customer_id)
      returning order_id into v_order_id;
      
    for i_product in (
      select pi.*
        from  inventories inv
              inner join product_information pi on 
                pi.product_id = inv.product_id
        where inv.warehouse_id = p_warehouse_id and
              inv.quantity_on_hand > 0
    ) loop
      insert into order_items (order_id, line_item_id, product_id, unit_price, quantity)
        values (v_order_id, v_line_item_id, i_product.product_id, i_product.list_price, 1);
      v_line_item_id := v_line_item_id + 1;
      v_order_total := v_order_total + i_product.list_price;
    end loop;
    update  orders 
        set  order_total = v_order_total
      where order_id = v_order_id;
    return v_customer_id;
    end;
  
  
  function fn_create_test_client_remake(
      p_first_name in customers.cust_first_name%type,
      p_last_name in customers.cust_last_name%type,
      p_warehouse_id in warehouses.warehouse_id%type
  ) return customers.customer_id%type
  is 
    v_customer_id customers.customer_id%type;
    v_order_id orders.order_id%type;
    v_line_item_id order_items.line_item_id%type := 1;
    v_order_total orders.order_total%type := 0;
    v_warehouse warehouses%rowtype;
  begin
    begin
      select w.* into v_warehouse
        from warehouses w
        where w.warehouse_id = p_warehouse_id;
      exception
        when no_data_found
        then return null;
    end;
    insert into customers (cust_first_name, cust_last_name)
      values (p_first_name, p_last_name)
      returning customer_id into v_customer_id;
    insert into orders (order_date, customer_id)
      values (sysdate, v_customer_id)
      returning order_id into v_order_id;
      
    for i_product in (
      select pi.*
        from  inventories inv
              inner join product_information pi on 
                pi.product_id = inv.product_id
        where inv.warehouse_id = p_warehouse_id and
              inv.quantity_on_hand > 0
    ) loop
      insert into order_items (order_id, line_item_id, product_id, unit_price, quantity)
        values (v_order_id, v_line_item_id, i_product.product_id, i_product.list_price, 1);
      v_line_item_id := v_line_item_id + 1;
      v_order_total := v_order_total + i_product.list_price;
    end loop;
    update  orders 
        set  order_total = v_order_total
      where order_id = v_order_id;
    return v_customer_id;
    end;
end;

--9.	Íàïèñàòü ôóíêöèþ, êîòîðàÿ âîçâðàòèò òàáëèöó (table of record),
--ñîäåðæàùóþ èíôîðìàöèþ î ÷àñòîòå âñòðå÷àåìîñòè îòäåëüíûõ ñèìâîëîâ âî âñåõ 
--íàçâàíèÿõ (è îïèñàíèÿõ) òîâàðà íà çàäàííîì ÿçûêå (ïåðåäàåòñÿ êîä ÿçûêà, 
--à òàêæå ïàðàìåòð, óêàçûâàþùèé, ó÷èòûâàòü ëè îïèñàíèÿ òîâàðîâ). 
--Âîçâðàùàåìàÿ òàáëèöà ñîñòîèò èç 2-õ ïîëåé: ñèìâîë, ÷àñòîòà âñòðå÷àåìîñòè â 
--âèäå ÷àñòíîãî îò êîë-âà äàííîãî ñèìâîëà ê êîëè÷åñòâó âñåõ 
--ñèìâîëîâ â íàçâàíèÿõ (è îïèñàíèÿõ) òîâàðà.
create type tp_result_char as 
object(
  ch nchar(1), 
  freq number
);
/

create type tp_result_char_table as
table of tp_result_char;
/

create or replace function fn_char_frequency(
  p_lang_id in product_descriptions.language_id%type,
  p_description in int
) return tp_result_char_table 
is 
  type tp_char_result_indexed_table is 
    table of tp_result_char index by binary_integer;
  v_result_table tp_result_char_table ;
  v_indexed_table tp_char_result_indexed_table;
  v_ch nchar(1);
  v_code binary_integer;
begin 
  v_result_table := tp_result_char_table ();
  for i_pd in (select  *
                 from  product_descriptions pd
                 where pd.language_id = p_lang_id
  ) loop
    for i_l in 1..length(i_pd.translated_name) loop
      v_ch := substr(i_pd.translated_name, i_l, 1);
      v_code := ascii(v_ch);
      if not v_indexed_table.exists(v_code) then
        v_indexed_table(v_code) := tp_result_char(v_ch, 0);
      end if;
      v_indexed_table(v_code).freq := v_indexed_table(v_code).freq + 1;
    end loop;
  end loop;
  
  if p_description>0 then 
    for i_pd in (select  *
                   from  product_descriptions pd
                   where pd.language_id = p_lang_id
    ) loop
      for i_l in 1..length(i_pd.translated_description) loop
        v_ch := substr(i_pd.translated_description, i_l, 1);
        v_code := ascii(v_ch);
        if not v_indexed_table.exists(v_code) then
          v_indexed_table(v_code) := tp_result_char(v_ch, 0);
        end if;
        v_indexed_table(v_code).freq := v_indexed_table(v_code).freq + 1;
      end loop;
    end loop;
  end if;
  
  v_code := v_indexed_table.first;
  while v_code is not null
    loop
      v_result_table.extend(1);
      v_result_table(v_result_table.last) := v_indexed_table(v_code);
      v_code := v_indexed_table.next(v_code);
    end loop;
  return v_result_table;
end;
/

declare
  v_result tp_result_char_table ;
begin
  v_result := fn_char_frequency('RU', 1);
  for i in 1..v_result.count
    loop
      dbms_output.put_line(v_result(i).ch || ' ' || v_result(i).freq);
    end loop;
end;
/

--10.	Íàïèñàòü ôóíêöèþ, êîòîðîé ïåðåäàåòñÿ sys_refcursor è êîòîðàÿ 
--ïî äàííîìó êóðñîðó ôîðìèðóåò HTML-òàáëèöó, ñîäåðæàùóþ èíôîðìàöèþ èç êóðñîðà.
--Òèï âîçâðàùàåìîãî çíà÷åíèÿ – clob.
declare
  v_cur sys_refcursor;
  v_result clob;
  function create_html_table(p_cur in out sys_refcursor)
    return clob
  is
    v_cur sys_refcursor := p_cur;
    v_cn integer;
    v_cols_desc dbms_sql.desc_tab2;
    v_cols_count integer;
    v_temp integer;
    v_result clob;
    v_str varchar2(1000);
  begin
    dbms_lob.createtemporary(v_result, true);
    v_cn := dbms_sql.to_cursor_number(v_cur);
    dbms_sql.describe_columns2(v_cn, v_cols_count, v_cols_desc);
    
    for i_index in 1 .. v_cols_count loop
      dbms_sql.define_column(v_cn, i_index, v_str, 1000);
    end loop;
    
    dbms_lob.append(v_result, '<table><tr>');
    
    for i_index in 1..v_cols_count loop
      dbms_lob.append(v_result, '<th>' || v_cols_desc(i_index).col_name || '</th>');
    end loop;
    dbms_lob.append(v_result, '</tr>');
  
    loop
      v_temp:=dbms_sql.fetch_rows(v_cn);
      exit when v_temp = 0;
      
      dbms_lob.append(v_result, '<tr>');
      for i_index in 1 .. v_cols_count
        loop
          dbms_sql.column_value(v_cn, i_index, v_str);
          dbms_lob.append(v_result, '<td>' || v_str || '</td>');
        end loop;
      dbms_lob.append(v_result, '</tr>');
    end loop;
    
    dbms_lob.append(v_result, '</table>');
    return v_result;
  end;
  
begin
  open v_cur for
    select c.* 
      from countries c;
  v_result := create_html_table(v_cur);
  dbms_output.put_line(v_result);
end;