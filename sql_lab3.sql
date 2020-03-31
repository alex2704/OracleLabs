--1. Выбрать с помощью иерархического запроса сотрудников 3-его уровня иерархии 
--(т.е. таких, у которых непосредственный начальник напрямую подчиняется руководителю организации).
--Упорядочить по коду сотрудника.
select  e.*
  from  employees e
  where level = 3
  start with  e.manager_id is null
  connect by  e.manager_id = prior e.employee_id
  order by e.employee_id;
  
  
--2. Для каждого сотрудника выбрать всех его начальников по иерархии. Вывести поля: код сотрудника, имя сотрудника
--(фамилия + имя через пробел), код начальника, имя начальника (фамилия + имя через пробел), кол-во промежуточных начальников
--между сотрудником и начальником из данной строки выборки. Если у какого-то сотрудника есть несколько начальников,
--то для данного сотрудника в выборке должно быть несколько строк с разными начальниками.
--Упорядочить по коду сотрудника, затем по уровню начальника 
--(первый – непосредственный начальник, последний – руководитель организации).
select  connect_by_root(e.employee_id) as employee_id,
        connect_by_root(e.first_name || ' ' || e.last_name) as employee_name,
        e.employee_id as manager_id,
        e.first_name || ' ' || e.last_name as manager_name,
        level - 2 as count_managers
  from  employees e
  where level > 1
  connect by  e.employee_id = prior e.manager_id
  order siblings by e.employee_id;
  
  
--  3. Для каждого сотрудника посчитать количество его подчиненных, как непосредственных, так и по иерархии.
--  Вывести поля: код сотрудника, имя сотрудника (фамилия + имя через пробел), общее кол-во подчиненных.

select  e.employee_id,
        e.first_name || ' ' || e.last_name as employee_name,
        count(e.employee_id) as count_employees
  from employees e
  where level > 1
  connect by e.employee_id = prior e.manager_id
  group by  e.employee_id, 
            e.first_name, 
            e.last_name, 
            e.first_name || ' ' || e.last_name
  order by  count_employees desc;


--4. Для каждого заказчика выбрать в виде строки через запятую даты его заказов. 
--Для конкатенации дат заказов использовать sys_connect_by_path (иерархический запрос).
--Для отбора «последних» строк использовать connect_by_isleaf.
select  o.customer_id,
        substr(sys_connect_by_path(to_char(o.order_date2, 'DD.MM.YYYY'), ', '), 3) as order_dates
  from  (
        select  o.customer_id,
                  lead(o.order_date) over (
                    partition by o.customer_id
                    order by o.order_date
                  ) as order_date1,
                  o.order_date as order_date2
            from  orders o
            group by  o.customer_id, o.order_date
          ) o
  where connect_by_isleaf = 1
  start with  o.order_date1 is null
  connect by  o.customer_id = prior(o.customer_id) and
              o.order_date1 = prior(o.order_date2);
              
--5. Выполнить задание № 4 c помощью обычного запроса с группировкой и функцией listagg.
select  o.customer_id,
        listagg(to_char(o.order_date, 'DD.MM.YYYY'), ', ')
          within group (order by o.order_date) as order_dates
  from  orders o
  group by  o.customer_id
;

--6. Выполнить задание № 2 с помощью рекурсивного запроса.

with emp_req(employee_id, employee_name, manager_id, manager_name, prev_manager_id, manager_level) as (
  select  e.employee_id,
          e.first_name || ' ' || e.last_name,
          e.employee_id,
          e.first_name || ' ' || e.last_name,
          e.manager_id,
          0
    from  employees e
  union all
  select  prev.employee_id,
          prev.employee_name,
          curr.employee_id,
          curr.first_name || ' ' || curr.last_name,
          curr.manager_id,
          manager_level + 1
    from  emp_req prev
          join employees curr on
            curr.employee_id = prev.prev_manager_id
)
select  r.employee_id,
        r.employee_name, 
        r.manager_id, 
        r.manager_name, 
        r.manager_level - 1 as manager_level
  from  emp_req r
  where manager_level > 0
  order by  r.employee_id,
            r.manager_level
;

--7. Выполнить задание № 3 с помощью рекурсивного запроса.
with emp_req(manager_id, manager_name, employee_id) as (
  select  e.employee_id,
          e.last_name || ' ' || e.first_name,
          e.employee_id
    from  employees e
  union all
  select  prev.manager_id,
          prev.manager_name,
          curr.employee_id
    from  emp_req prev
          join  employees curr
            on  curr.manager_id=prev.employee_id
)
select  r.manager_id,
        r.manager_name,
        count(*)-1 as emp_count
  from  emp_req r
  group by  r.manager_id,
            r.manager_name
  order by  emp_count desc
;

--8. Каждому менеджеру по продажам сопоставить последний его заказ. Менеджером по продажам считаем сотрудников,
--код должности которых: «SA_MAN» и «SA_REP». Для выборки последних заказов по менеджерам использовать подзапрос
--с применением аналитических функций (например в подзапросе выбирать дату следующего заказа менеджера, 
--а во внешнем запросе «оставить» только те строки, у которых следующего заказа нет). 
--Вывести поля: код менеджера, имя менеджера (фамилия + имя через пробел),
--код клиента, имя клиента (фамилия + имя через пробел), дата заказа, сумма заказа, количество различных позиций в заказе. 
--Упорядочить данные по дате заказа в обратном порядке, затем по сумме заказа в обратном порядке, затем по коду сотрудника.
--Тех менеджеров, у которых нет заказов, вывести в конце.
select  e.employee_id,
        e.first_name || ' ' || e.last_name as employee_name,
        c.customer_id,
        c.cust_first_name || ' ' || c.cust_last_name as customer_name,
        o.order_date,
        o.order_total,
        (
          select  count(oi.product_id)
            from  order_items oi
            where oi.order_id = o.order_id
        ) as items_count
  from  employees e
        left join (
          select  o.*,
                  lead(o.order_date) over(
                    partition by o.sales_rep_id
                    order by o.order_date
                  ) as next_order
            from  orders o
        ) o on
          o.sales_rep_id = e.employee_id and
          o.next_order is null
        left join customers c on
          c.customer_id = o.customer_id          
  where e.job_id in ('SA_MAN', 'SA_REP')
  order by  o.order_date desc nulls last,
            o.order_total desc nulls last,
            e.employee_id;
            
--9. Для каждого месяца текущего года найти первые и последние рабочие и выходные дни с учетом праздников и переносов
--выходных дней (на 2016 год эту информацию можно посмотреть, например, на странице http://www.interfax.ru/russia/469373).
--Для формирования списка всех дней текущего года использовать иерархический запрос, оформленный в виде подзапроса в секции with.
--Праздничные дни и переносы выходных также задать в виде подзапроса в секции with (с помощью union all перечислить все даты
--, в которых рабочие/выходные дни не совпадают с обычной логикой определения выходного дня как субботы и воскресения). 
--Запрос должен корректно работать, если добавить изменить какие угодно выходные/рабочие дни в данном подзапросе. 
--Вывести поля: месяц в виде первого числа месяца, первый выходной день месяца, последний выходной день, 
--первый праздничный день, последний праздничный день.
with 
days as
(
  select  trunc(sysdate, 'yyyy') + level - 1 as dt
    from  dual
    connect by  trunc(sysdate, 'yyyy') + level - 1 <
                  add_months(trunc(sysdate, 'yyyy'), 12)
),
holidays as 
(
  select date'2018-01-01' as dt, 1 as comments from dual union all
  select date'2018-01-02', 1 from dual union all
  select date'2018-01-03', 1 from dual union all
  select date'2018-01-04', 1 from dual union all
  select date'2018-01-05', 1 from dual union all
  select date'2018-01-08', 1 from dual union all
  select date'2018-02-23', 1 from dual union all
  select date'2018-03-08', 1 from dual union all
  select date'2018-03-09', 1 from dual union all
  select date'2018-04-28', 0 from dual union all
  select date'2018-04-30', 1 from dual union all
  select date'2018-05-01', 1 from dual union all
  select date'2018-05-02', 1 from dual union all
  select date'2018-05-09', 1 from dual union all
  select date'2018-06-09', 0 from dual union all
  select date'2018-06-11', 1 from dual union all
  select date'2018-06-12', 1 from dual union all
  select date'2018-11-05', 1 from dual union all
  select date'2018-12-29', 0 from dual union all
  select date'2018-12-31', 1 from dual
)
select  trunc(d.dt, 'MM') as dt,
        min(
          case when d.comments = 1 then d.dt
          end
        ) as first_weekend,
        max(
          case when d.comments = 1 then d.dt
          end
        ) as last_weekend,
        min(
          case when d.comments = 0 then d.dt
          end
        ) as first_working,
        max(
          case when d.comments = 0 then d.dt
          end
        ) as last_working
  from  (
          select  d.dt,
                  nvl(
                    h.comments, 
                    case 
                      when to_char(d.dt, 'Dy', 'nls_date_language=english') in ('Sat', 'Sun') then 1
                      else 0
                    end
                  ) as comments
            from  days d
                  left join holidays h on
                    h.dt = d.dt
        ) d
  group by  trunc(d.dt, 'MM')
  order by  dt;
--10. 3-м самых эффективным по сумме заказов за 1999 год менеджерам по продажам увеличить зарплату еще на 20%.
start transaction;
update  employees e
  set e.salary = e.salary * 1.2
  where employee_id in (
    select em.employee_id
      from (
            select  e.employee_id,
                    sum_orders
              from  employees e
                    join  (
                          select  o.sales_rep_id,
                                  sum(o.order_total) as sum_orders
                            from  orders o
                                where date'1999-01-01' <= o.order_date and o.order_date < date'2000-01-01'
                                group by  o.sales_rep_id
                            ) o on
                              o.sales_rep_id = e.employee_id
                      where e.job_id in('SA_MAN', 'SA_REP')
                      order by  sum_orders desc
                  ) em
            where rownum <= 3
        );
select  e.employee_id,
        sum_orders,
        e.salary
  from  employees e
        join (
          select  o.sales_rep_id,
                  sum(o.order_total) as sum_orders
            from  orders o
            where date'1999-01-01' <= o.order_date and o.order_date < date'2000-01-01'
            group by  o.sales_rep_id
        ) o on
          o.sales_rep_id = e.employee_id
  order by  sum_orders desc;
rollback;
--11. Завести нового клиента ‘Старый клиент’ с менеджером, который является руководителем организации.
--Остальные поля клиента – по умолчанию.
start transaction;
insert into customers (cust_last_name, cust_first_name, account_mgr_id)
select  'Клиент',
        'Старый',
        e.employee_id
  from  employees e
  where e.manager_id is null
;
select  c.*
  from  customers c
  where c.cust_last_name = 'Клиент'
;
rollback;

--12. Для клиента, созданного в предыдущем запросе, (найти можно по максимальному id клиента),
--продублировать заказы всех клиентов за 1990 год. (Здесь будет 2 запроса,
--для дублирования заказов и для дублирования позиций заказа).
insert into orders (order_date, order_mode, customer_id, order_status, order_total, sales_rep_id, promotion_id)
select  o.order_date,
        o.order_mode,
        (
          select  max(c.customer_id) as customer_id
            from  customers c
        ) as customer_id,
        o.order_status,
        o.order_total,
        o.sales_rep_id,
        o.promotion_id
  from  orders o
  where date'1990-01-01' <= o.order_date and o.order_date < date'1991-01-01'
;

insert  into order_items (order_id, line_item_id, product_id, unit_price, quantity)
select  pos_order.order_id,
        oi.line_item_id,
        oi.product_id,
        oi.unit_price,
        oi.quantity
  from  order_items oi
        join orders o on
          o.order_id = oi.order_id
        join orders pos_order on
          pos_order.order_date = o.order_date and
          pos_order.customer_id = (
            select  max(c.customer_id) as customer_id
              from  customers c
          )
  where date'1990-01-01' <= o.order_date and o.order_date < date'1991-01-01'
;

--13. Для каждого клиента удалить самый первый заказ. 
--Должно быть 2 запроса: первый – для удаления позиций в заказах, второй – на удаление собственно заказов).
delete  from order_items oi
  where oi.order_id in (
          select  o.order_id
            from  orders o
                  join (
                    select  o.customer_id,
                            min(o.order_date) as first_order
                      from  orders o
                      group by  o.customer_id
                  ) pos_ord on
                    pos_ord.customer_id = o.customer_id and
                    pos_ord.first_order = o.order_date
        )
;

delete from orders o
  where o.order_id in (
                        select  o.order_id
                          from  orders o
                                join (
                                  select  o.customer_id,
                                          min(o.order_date) as first_order
                                    from  orders o
                                    group by  o.customer_id
                                ) pos_ord on
                                  pos_ord.customer_id = o.customer_id and
                                  pos_ord.first_order = o.order_date
                        )
;
--14. Для товаров, по которым не было ни одного заказа, уменьшить цену в 2 раза (округлив до целых)
--и изменить название, приписав префикс ‘Супер Цена! ’.
update  product_information pi
  set pi.list_price = round(pi.list_price / 2),
      pi.min_price = round(pi.min_price / 2),
      pi.product_name = 'Супер Цена! ' || pi.product_name
    where not exists  (
                      select  *
                        from  order_items oi
                        where oi.product_id = pi.product_id
                      );

select  *
  from product_information pi
    where not exists  (
                      select  *
                        from  order_items oi
                        where oi.product_id = pi.product_id
                      );  


