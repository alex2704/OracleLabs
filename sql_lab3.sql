--1. ������� � ������� �������������� ������� ����������� 3-��� ������ �������� 
--(�.�. �����, � ������� ���������������� ��������� �������� ����������� ������������ �����������).
--����������� �� ���� ����������.
select  e.*
  from  employees e
  where level = 3
  start with  e.manager_id is null
  connect by  e.manager_id = prior e.employee_id
  order by e.employee_id;
  
  
--2. ��� ������� ���������� ������� ���� ��� ����������� �� ��������. ������� ����: ��� ����������, ��� ����������
--(������� + ��� ����� ������), ��� ����������, ��� ���������� (������� + ��� ����� ������), ���-�� ������������� �����������
--����� ����������� � ����������� �� ������ ������ �������. ���� � ������-�� ���������� ���� ��������� �����������,
--�� ��� ������� ���������� � ������� ������ ���� ��������� ����� � ������� ������������.
--����������� �� ���� ����������, ����� �� ������ ���������� 
--(������ � ���������������� ���������, ��������� � ������������ �����������).
select  connect_by_root(e.employee_id) as employee_id,
        connect_by_root(e.first_name || ' ' || e.last_name) as employee_name,
        e.employee_id as manager_id,
        e.first_name || ' ' || e.last_name as manager_name,
        level - 2 as count_managers
  from  employees e
  where level > 1
  connect by  e.employee_id = prior e.manager_id
  order siblings by e.employee_id;
  
  
--  3. ��� ������� ���������� ��������� ���������� ��� �����������, ��� ����������������, ��� � �� ��������.
--  ������� ����: ��� ����������, ��� ���������� (������� + ��� ����� ������), ����� ���-�� �����������.

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


--4. ��� ������� ��������� ������� � ���� ������ ����� ������� ���� ��� �������. 
--��� ������������ ��� ������� ������������ sys_connect_by_path (������������� ������).
--��� ������ ����������� ����� ������������ connect_by_isleaf.
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
              
--5. ��������� ������� � 4 c ������� �������� ������� � ������������ � �������� listagg.
select  o.customer_id,
        listagg(to_char(o.order_date, 'DD.MM.YYYY'), ', ')
          within group (order by o.order_date) as order_dates
  from  orders o
  group by  o.customer_id
;

--6. ��������� ������� � 2 � ������� ������������ �������.

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

--7. ��������� ������� � 3 � ������� ������������ �������.
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

--8. ������� ��������� �� �������� ����������� ��������� ��� �����. ���������� �� �������� ������� �����������,
--��� ��������� �������: �SA_MAN� � �SA_REP�. ��� ������� ��������� ������� �� ���������� ������������ ���������
--� ����������� ������������� ������� (�������� � ���������� �������� ���� ���������� ������ ���������, 
--� �� ������� ������� ���������� ������ �� ������, � ������� ���������� ������ ���). 
--������� ����: ��� ���������, ��� ��������� (������� + ��� ����� ������),
--��� �������, ��� ������� (������� + ��� ����� ������), ���� ������, ����� ������, ���������� ��������� ������� � ������. 
--����������� ������ �� ���� ������ � �������� �������, ����� �� ����� ������ � �������� �������, ����� �� ���� ����������.
--��� ����������, � ������� ��� �������, ������� � �����.
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
            
--9. ��� ������� ������ �������� ���� ����� ������ � ��������� ������� � �������� ��� � ������ ���������� � ���������
--�������� ���� (�� 2016 ��� ��� ���������� ����� ����������, ��������, �� �������� http://www.interfax.ru/russia/469373).
--��� ������������ ������ ���� ���� �������� ���� ������������ ������������� ������, ����������� � ���� ���������� � ������ with.
--����������� ��� � �������� �������� ����� ������ � ���� ���������� � ������ with (� ������� union all ����������� ��� ����
--, � ������� �������/�������� ��� �� ��������� � ������� ������� ����������� ��������� ��� ��� ������� � �����������). 
--������ ������ ��������� ��������, ���� �������� �������� ����� ������ ��������/������� ��� � ������ ����������. 
--������� ����: ����� � ���� ������� ����� ������, ������ �������� ���� ������, ��������� �������� ����, 
--������ ����������� ����, ��������� ����������� ����.
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
--10. 3-� ����� ����������� �� ����� ������� �� 1999 ��� ���������� �� �������� ��������� �������� ��� �� 20%.
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
--11. ������� ������ ������� ������� ������ � ����������, ������� �������� ������������� �����������.
--��������� ���� ������� � �� ���������.
start transaction;
insert into customers (cust_last_name, cust_first_name, account_mgr_id)
select  '������',
        '������',
        e.employee_id
  from  employees e
  where e.manager_id is null
;
select  c.*
  from  customers c
  where c.cust_last_name = '������'
;
rollback;

--12. ��� �������, ���������� � ���������� �������, (����� ����� �� ������������� id �������),
--�������������� ������ ���� �������� �� 1990 ���. (����� ����� 2 �������,
--��� ������������ ������� � ��� ������������ ������� ������).
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

--13. ��� ������� ������� ������� ����� ������ �����. 
--������ ���� 2 �������: ������ � ��� �������� ������� � �������, ������ � �� �������� ���������� �������).
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
--14. ��� �������, �� ������� �� ���� �� ������ ������, ��������� ���� � 2 ���� (�������� �� �����)
--� �������� ��������, �������� ������� ������ ����! �.
update  product_information pi
  set pi.list_price = round(pi.list_price / 2),
      pi.min_price = round(pi.min_price / 2),
      pi.product_name = '����� ����! ' || pi.product_name
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


