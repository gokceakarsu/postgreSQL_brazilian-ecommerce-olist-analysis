

--Case 1 : Sipariş Analizi
--Question 1 : 
---Aylık olarak order dağılımını inceleyiniz. Tarih verisi için order_approved_at kullanılmalıdır.

SELECT	to_char(order_approved_at, 'YYYY-MM') AS date_y_m,
		COUNT(DISTINCT order_id) AS order_count
FROM orders
WHERE order_approved_at IS NOT null
GROUP BY 1
ORDER BY 1;

--Question 2 : 
---Aylık olarak order status kırılımında order sayılarını inceleyiniz. Sorgu sonucunda çıkan outputu excel ile görselleştiriniz. Dramatik bir düşüşün ya da yükselişin olduğu aylar var mı? Veriyi inceleyerek yorumlayınız.

SELECT	to_char(order_approved_at, 'YYYY-MM') as date_y_m,
		order_status,
		count(distinct order_id) as order_count
FROM orders
WHERE order_approved_at IS NOT null
GROUP BY 1,2
ORDER BY 1;

---toplam dağılım--
SELECT	to_char(order_approved_at, 'YYYY-MM') as date_y_m,
		count(distinct order_id) as total_order_count
FROM orders
WHERE order_approved_at IS NOT null
GROUP BY 1
ORDER BY 1;
--Question 3 : 
---Ürün kategorisi kırılımında sipariş sayılarını inceleyiniz. Özel günlerde öne çıkan kategoriler nelerdir? Örneğin yılbaşı, sevgililer günü…


--Ürün kategori kırılında teslim edilen siparişler
SELECT tr.category_name_english,
       COUNT(distinct o.order_id) AS order_count
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN translation AS tr ON tr.category_name=p.product_category_name
WHERE o.order_status = 'delivered' 
GROUP BY 1
ORDER BY 2 DESC;


--katefori bazlı aylık sipariş dağılımı--- 2018 yılbaşı noel 
SELECT	tr.category_name_english,
		COUNT(distinct o.order_id) AS order_count
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN translation AS tr ON tr.category_name=p.product_category_name
WHERE o.order_status = 'delivered' 
AND tr.category_name_english IS NOT NULL 
AND o.order_purchase_timestamp BETWEEN '2017-12-01' AND '2018-01-01' 
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

--katefori bazlı aylık sipariş dağılımı--- 2017 anneler günü 14 mayıs 
SELECT	tr.category_name_english,
		COUNT(distinct o.order_id) AS order_count
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN translation AS tr ON tr.category_name=p.product_category_name
WHERE o.order_status = 'delivered' 
AND tr.category_name_english IS NOT NULL 
AND o.order_purchase_timestamp BETWEEN '2017-04-14' AND '2017-05-14' 
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;


--katefori bazlı aylık sipariş dağılımı--- 12 ekim çocuklar günü 2017
SELECT	tr.category_name_english,
		COUNT(distinct o.order_id) AS order_count
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN translation AS tr ON tr.category_name=p.product_category_name
WHERE o.order_status = 'delivered' 
AND tr.category_name_english IS NOT NULL 
AND o.order_purchase_timestamp BETWEEN '2017-09-12' AND '2017-10-12' 
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;


--katefori bazlı aylık sipariş dağılımı--- 2017 black friday
SELECT	tr.category_name_english,
		COUNT(distinct o.order_id) AS order_count
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN translation AS tr ON tr.category_name=p.product_category_name
WHERE o.order_status = 'delivered' 
AND tr.category_name_english IS NOT NULL 
AND o.order_purchase_timestamp::date  = '2017-11-24' 
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;


--Question 4 : 
---Haftanın günleri(pazartesi, perşembe, ….) ve ay günleri (ayın 1’i,2’si gibi) bazında order sayılarını inceleyiniz. Yazdığınız sorgunun outputu ile excel’de bir görsel oluşturup yorumlayınız.



---haftanın günleri
SELECT	to_char(order_purchase_timestamp, 'DAY') AS day_of_week,
		COUNT(DISTINCT order_id) AS order_count
FROM orders
GROUP BY 1
ORDER BY 2 DESC
;

----ayın günleri
SELECT	to_char(order_purchase_timestamp, 'DD') AS day_of_month,
		COUNT(DISTINCT order_id) AS order_count
FROM orders
GROUP BY 1
ORDER BY 1 
;


--Case 2 : Müşteri Analizi *********
--Question 1 : 
---Hangi şehirlerdeki müşteriler daha çok alışveriş yapıyor? Müşterinin şehrini en çok sipariş verdiği şehir olarak belirleyip analizi ona göre yapınız. 


WITH customer_orders AS (
    SELECT	
        cs.customer_unique_id,
        cs.customer_city,
        COUNT(DISTINCT o.order_id) AS order_count,
        ROW_NUMBER() OVER(PARTITION BY cs.customer_unique_id ORDER BY COUNT(o.order_id) DESC) AS row_num
    FROM customers AS cs
    JOIN  orders AS o ON o.customer_id = cs.customer_id
	--WHERE customer_unique_id='f34cd7fd85a1f8baff886edf09567be3'
    GROUP BY 1,2
    ORDER BY 1
),
customer_orders_2 AS (
    SELECT
        co.customer_unique_id,
        co.customer_city
    FROM customer_orders AS co
    WHERE co.row_num = 1
    GROUP BY 1,2
)
SELECT
    co2.customer_city,
    SUM(co.order_count) AS order_count
FROM customer_orders AS co
JOIN customer_orders_2 AS co2 ON co.customer_unique_id = co2.customer_unique_id
GROUP BY 1
ORDER BY 2 DESC;


---Örneğin; Sibel Çanakkale’den 3, Muğla’dan 8 ve İstanbul’dan 10 sipariş olmak üzere 3 farklı şehirden sipariş veriyor. Sibel’in şehrini en çok sipariş verdiği şehir olan İstanbul olarak seçmelisiniz ve Sibel’in yaptığı siparişleri İstanbul’dan 21 sipariş vermiş şekilde görünmelidir.

--Case 3: Satıcı Analizi
--Question 1 : 
---Siparişleri en hızlı şekilde müşterilere ulaştıran satıcılar kimlerdir? Top 5 getiriniz. Bu satıcıların order sayıları ile ürünlerindeki yorumlar ve puanlamaları inceleyiniz ve yorumlayınız.

WITH seller_information AS 
(
    SELECT 
        s.seller_id,
        COUNT(o.order_id) AS order_count,
        AVG(o.order_delivered_customer_date - o.order_approved_at) AS avg_delivery_time,
        COUNT(r.review_comment_message) AS message_count
    FROM  sellers AS s
    LEFT JOIN order_items AS oi ON s.seller_id = oi.seller_id
    LEFT JOIN orders AS o ON oi.order_id = o.order_id
    LEFT JOIN reviews AS r ON o.order_id = r.order_id
    WHERE order_delivered_customer_date IS NOT NULL AND order_approved_at IS NOT NULL
    GROUP BY 1
)
SELECT
    ROUND(AVG(order_count), 0) AS average_order_count,
    ROUND(AVG(message_count), 0) AS average_message_count
FROM 
    seller_information;
--ORTALAMA ORT SİPARİŞ ORTALAMASI 37 , yorum sayısı 16


SELECT 
	s.seller_id,
	ROUND(AVG(r.review_score),0) AS avg_review_score,
	COUNT(o.order_id) AS order_count,
	AVG(AGE(o.order_delivered_customer_date , o.order_approved_at))AS avg_delivery_time,
	COUNT(r.review_comment_message) AS message_count
FROM sellers AS s
LEFT JOIN order_items AS oi ON s.seller_id=oi.seller_id
LEFT JOIN orders AS o ON oi.order_id=o.order_id
LEFT JOIN reviews AS r ON o.order_id=r.order_id
WHERE order_delivered_customer_date IS NOT NULL AND order_approved_at IS NOT NULL
GROUP BY 1
HAVING COUNT(o.order_id)> 37
AND
COUNT(r.review_comment_message)>16
ORDER BY 4
LIMIT 5
;

	---yorumlar
    SELECT 
        s.seller_id,
		r.review_comment_message
    FROM  sellers AS s
    LEFT JOIN order_items AS oi ON s.seller_id = oi.seller_id
    LEFT JOIN orders AS o ON oi.order_id = o.order_id
    LEFT JOIN reviews AS r ON o.order_id = r.order_id
    WHERE s.seller_id='289cdb325fb7e7f891c38608bf9e0962'
    GROUP BY 1,2
--Question 2 : 
---Hangi satıcılar daha fazla kategoriye ait ürün satışı yapmaktadır? 



SELECT
	s.seller_id,
	COUNT(DISTINCT tr.category_name_english) AS category_count,
	COUNT(DISTINCT oi.order_id) AS order_count
FROM sellers AS s
LEFT JOIN order_items AS oi ON s.seller_id=oi.seller_id
LEFT JOIN products AS pr ON oi.product_id=pr.product_id
LEFT JOIN translation AS tr ON pr.product_category_name=tr.category_name
GROUP BY 1
ORDER BY 2 DESC
LIMIT 100; 


---KATEGORİ SAYISININ SİPARİŞ SAYISI ÜZERİNE ETKİSİ
WITH seller_category_count AS (
    SELECT
	s.seller_id,
	COUNT(DISTINCT tr.category_name_english) AS category_count,
	COUNT(DISTINCT oi.order_id) AS order_count
FROM sellers AS s
LEFT JOIN order_items AS oi ON s.seller_id=oi.seller_id
LEFT JOIN products AS pr ON oi.product_id=pr.product_id
LEFT JOIN translation AS tr ON pr.product_category_name=tr.category_name
GROUP BY 1
)
SELECT 
    category_count,
    ROUND(AVG(order_count)) AS avg_order_count
FROM seller_category_count
GROUP BY 1
ORDER BY 1;




--Case 4 : Payment Analizi
--Question 1 : 
---Ödeme yaparken taksit sayısı fazla olan kullanıcılar en çok hangi bölgede yaşamaktadır? Bu çıktıyı yorumlayınız.


---en çok müşteriye ve siparişe sahip şehirler
	SELECT 
	cs.customer_state,
	cs.customer_city,
	COUNT(DISTINCT customer_unique_id) AS customer_count,
	COUNT(DISTINCT o.order_id) AS order_count
FROM customers AS cs
LEFT JOIN orders AS o ON o.customer_id=cs.customer_id
LEFT JOIN payments as py ON py.order_id=o.order_id	
WHERE payment_type='credit_card' AND payment_installments>2
GROUP BY 1,2
HAVING COUNT(o.order_id)>10
ORDER BY 4 DESC;

---taksit sayıları-sipariş sayıları-müşteri sayıları ilişkisi

	SELECT 
	cs.customer_state,
	py.payment_installments,
	COUNT(DISTINCT customer_unique_id) AS customer_count,
	COUNT(DISTINCT o.order_id) AS order_count
FROM customers AS cs
LEFT JOIN orders AS o ON o.customer_id=cs.customer_id
LEFT JOIN payments as py ON py.order_id=o.order_id	
WHERE payment_type='credit_card' AND payment_installments>2
GROUP BY 1,2
HAVING COUNT(o.order_id)>10
ORDER BY 2 DESC;


--Question 2 : 
---Ödeme tipine göre başarılı order sayısı ve toplam başarılı ödeme tutarını hesaplayınız. En çok kullanılan ödeme tipinden en az olana göre sıralayınız.

SELECT 
	DISTINCT py.payment_type,
	COUNT(o.order_id)OVER (PARTITION BY payment_type) AS suc_order_count,
	ROUND(SUM(py.payment_value)OVER (PARTITION BY payment_type)) AS total_payment
FROM payments AS py
LEFT JOIN orders AS o ON o.order_id = py.order_id
WHERE o.order_status = 'delivered'
ORDER BY 3 DESC;

--Question 3 : 
---Tek çekimde ve taksitle ödenen siparişlerin kategori bazlı analizini yapınız. En çok hangi kategorilerde taksitle ödeme kullanılmaktadır?

---TEK ÇEKİM-PEŞİN ÖDEME
SELECT	tr.category_name_engliSh,
		COUNT(DISTINCT o.order_id)
FROM payments AS py 
LEFT JOIN order_items AS oi ON oi.order_id = py.order_id
LEFT JOIN orders AS o ON o.order_id = oi.order_id
LEFT JOIN products AS pr ON pr.product_id=oi.product_id
LEFT JOIN translation AS tr ON tr.category_name=pr.product_category_name
WHERE py.payment_installments = 1
AND tr.category_name_engliSh IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC;

---TAKSİTLİ ÖDEME
SELECT	tr.category_name_engliSh,
		COUNT(DISTINCT o.order_id)
FROM payments AS py 
LEFT JOIN order_items AS oi ON oi.order_id = py.order_id
LEFT JOIN orders AS o ON o.order_id = oi.order_id
LEFT JOIN products AS pr ON pr.product_id=oi.product_id
LEFT JOIN translation AS tr ON tr.category_name=pr.product_category_name
WHERE py.payment_installments > 1
AND tr.category_name_engliSh IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC;
--Case 5 : RFM Analizi

---Aşağıdaki e_commerce_data_.csv doyasındaki veri setini kullanarak RFM analizi yapınız. 
---Recency hesaplarken bugünün tarihi değil en son sipariş tarihini baz alınız. 

SELECT * FROM rfm;
SELECT MAX(invoicedate::date) FROM rfm; --2011-12-09

--Recency 
SELECT
	customer_id,
	MAX(invoicedate::date) AS max_invoicedate,
	'2011-12-09'::date - MAX(invoicedate::date) AS recency
FROM rfm
WHERE customer_id IS NOT NULL and invoiceno NOT LIKE 'C%'
GROUP BY 1 
ORDER BY 3;

--Frequency
SELECT 
	customer_id,
	COUNT(DISTINCT invoiceno) AS frequency
FROM rfm
WHERE customer_id IS NOT NULL and invoiceno NOT LIKE 'C%'
GROUP BY 1
ORDER BY 2 DESC;

--Monetory
SELECT 
	customer_id,
	ROUND(SUM(quantity*unitprice)::numeric) AS monetary
FROM rfm
WHERE customer_id IS NOT NULL and invoiceno NOT LIKE 'C%'
GROUP BY 1
ORDER BY 2 DESC;

--R-F-M Analizi

WITH recency AS
(
	SELECT
	customer_id,
	MAX(invoicedate::date) AS max_invoicedate,
	'2011-12-09'::date - MAX(invoicedate::date) AS recency
FROM rfm
WHERE customer_id IS NOT NULL and invoiceno NOT LIKE 'C%'
GROUP BY 1 
ORDER BY 3
),
frequency AS
(
SELECT 
	customer_id,
	COUNT(DISTINCT invoiceno) AS frequency
FROM rfm
WHERE customer_id IS NOT NULL and invoiceno NOT LIKE 'C%'
GROUP BY 1
ORDER BY 2 DESC
),
monetary AS
(
SELECT 
	customer_id,
	ROUND(SUM(quantity*unitprice)::numeric) AS monetary
FROM rfm
WHERE customer_id IS NOT NULL and invoiceno NOT LIKE 'C%'
GROUP BY 1
ORDER BY 2 DESC
)
SELECT
	r.customer_id,
	r.recency,
	NTILE(5) OVER (ORDER BY recency DESC) AS receny_score,
	f.frequency,
	CASE WHEN f.frequency>=1 AND f.frequency<=4
	THEN f.frequency
	ELSE 5 END AS frequceny_score,
	m.monetary,
	NTILE(5) OVER (ORDER BY monetary)AS monetary_score
FROM recency AS r
JOIN frequency AS f ON r.customer_id=f.customer_id
JOIN monetary AS m ON r.customer_id=m.customer_id
ORDER BY f.frequency DESC;


--r-f-m score table---

	WITH rfm_score_table_2 AS 
	(
		WITH rfm_score_table AS 
	(
	WITH recency AS
(
	SELECT
	customer_id,
	MAX(invoicedate::date) AS max_invoicedate,
	'2011-12-09'::date - MAX(invoicedate::date) AS recency
FROM rfm
WHERE customer_id IS NOT NULL and invoiceno NOT LIKE 'C%'
GROUP BY 1 
ORDER BY 3
),
frequency AS
(
SELECT 
	customer_id,
	COUNT(DISTINCT invoiceno) AS frequency
FROM rfm
WHERE customer_id IS NOT NULL and invoiceno NOT LIKE 'C%'
GROUP BY 1
ORDER BY 2 DESC
),
monetary AS
(
SELECT 
	customer_id,
	ROUND(SUM(quantity*unitprice)::numeric) AS monetary
FROM rfm
WHERE customer_id IS NOT NULL and invoiceno NOT LIKE 'C%'
GROUP BY 1
ORDER BY 2 DESC
)
SELECT
	r.customer_id,
	r.recency,
	NTILE(5) OVER (ORDER BY recency DESC) AS recency_score,
	f.frequency,
	CASE WHEN f.frequency>=1 AND f.frequency<=4
	THEN f.frequency
	ELSE 5 END AS frequency_score,
	m.monetary,
	NTILE(5) OVER (ORDER BY monetary)AS monetary_score
FROM recency AS r
JOIN frequency AS f ON r.customer_id=f.customer_id
JOIN monetary AS m ON r.customer_id=m.customer_id
ORDER BY f.frequency DESC
		)
	SELECT 
    rfm.customer_id,
    rfm.recency_score::text || '-' || rfm.frequency_score::text || '-' || rfm.monetary_score::text as rfm_score
FROM rfm_score_table AS rfm
		)
	SELECT 
	rst.rfm_score,
	COUNT(rst.customer_id) AS count_customer
	FROM rfm_score_table_2 AS rst
	GROUP BY 1
	ORDER BY 2 DESC;
	
--r-f score table---

WITH last_order AS (
    SELECT
        customer_id AS customer,
        MAX(order_date) AS last_orders
    FROM
        orders
    GROUP BY
        customer_id
),
rfm_scores AS (
    SELECT 
        c.customer_id,
        c.company_name,
        -- Recency: Son sipariş ile en son tarihe kadar geçen süreyi hesapla
        (SELECT MAX(order_date) FROM orders) - last_order.last_orders AS recency,
        -- Frequency: Müşterinin toplam sipariş sayısı
        COUNT(o.order_id) AS frequency,
        -- Monetary: Müşterinin toplam harcama miktarı
        ROUND(SUM(od.unit_price * od.quantity * (1 - od.discount))::numeric, 2) AS monetary
    FROM 
        customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_details od ON o.order_id = od.order_id
    JOIN last_order ON c.customer_id = last_order.customer
    WHERE o.shipped_date IS NOT NULL  -- Yalnızca sevk edilen siparişler
    GROUP BY c.customer_id, c.company_name, last_order.last_orders
)
SELECT 
    rfm_scores.customer_id,
    rfm_scores.company_name,
    rfm_scores.recency,
    rfm_scores.frequency,
    rfm_scores.monetary,
    -- Recency NTILE: Recency skorunu NTILE kullanarak belirle
    NTILE(5) OVER (ORDER BY rfm_scores.recency) AS recency_ntile,
    -- Frequency Segmentasyonu: Frequency'ye göre 1-5 arasında puan ver
    CASE 
        WHEN rfm_scores.frequency >= 50 THEN 5
        WHEN rfm_scores.frequency BETWEEN 20 AND 49 THEN 4
        WHEN rfm_scores.frequency BETWEEN 1 AND 19 THEN 3
        ELSE 1
    END AS frequency_score,
    NTILE(5) OVER (ORDER BY rfm_scores.monetary DESC) AS monetary_ntile,
    NTILE(5) OVER (ORDER BY rfm_scores.recency + rfm_scores.frequency + rfm_scores.monetary DESC) AS total_rfm_ntile,
    CONCAT(
        NTILE(5) OVER (ORDER BY rfm_scores.recency), '-', 
        CASE 
            WHEN rfm_scores.frequency >= 50 THEN 5
            WHEN rfm_scores.frequency BETWEEN 20 AND 49 THEN 4
            WHEN rfm_scores.frequency BETWEEN 10 AND 19 THEN 3
            ELSE 1
        END
    ) AS r_f_table
FROM 
    rfm_scores
JOIN orders o ON rfm_scores.customer_id = o.customer_id
GROUP BY 
    rfm_scores.customer_id, 
    rfm_scores.company_name, 
    rfm_scores.recency, 
    rfm_scores.frequency, 
    rfm_scores.monetary
ORDER BY 
    total_rfm_ntile DESC, recency_ntile, frequency_score, monetary_ntile DESC;


