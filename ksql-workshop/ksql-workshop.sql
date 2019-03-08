-- ###################################################
-- These are the commands used during the workshop. 
-- You can use this file to catch up to certain stages
-- of the workshop if you want.
-- ###################################################

SET 'auto.offset.reset' = 'earliest';

CREATE STREAM CUSTOMERS_SRC (id BIGINT, first_name VARCHAR, last_name VARCHAR, email VARCHAR, gender VARCHAR, club_status VARCHAR, comments VARCHAR) WITH (KAFKA_TOPIC='asgard.demo.CUSTOMERS', VALUE_FORMAT='JSON');

CREATE STREAM CUSTOMERS_SRC_REKEY \
        WITH (PARTITIONS=1, VALUE_FORMAT='AVRO') AS \
        SELECT * FROM CUSTOMERS_SRC PARTITION BY ID;

CREATE STREAM RATINGS WITH (KAFKA_TOPIC='ratings', VALUE_FORMAT='AVRO');

CREATE STREAM POOR_RATINGS AS SELECT * FROM ratings WHERE STARS <3 AND CHANNEL='iOS';

CREATE TABLE CUSTOMERS WITH (KAFKA_TOPIC='CUSTOMERS_SRC_REKEY', VALUE_FORMAT ='AVRO', KEY='ID');

CREATE STREAM RATINGS_WITH_CUSTOMER_DATA WITH (PARTITIONS=1) AS \
SELECT R.RATING_ID, R.CHANNEL, R.STARS, R.MESSAGE, \
       C.ID, C.CLUB_STATUS, C.EMAIL, \
       C.FIRST_NAME, C.LAST_NAME \
FROM RATINGS R \
     INNER JOIN CUSTOMERS C \
       ON R.USER_ID = C.ID;

CREATE STREAM UNHAPPY_PLATINUM_CUSTOMERS AS \
SELECT CLUB_STATUS, EMAIL, STARS, MESSAGE \
FROM   RATINGS_WITH_CUSTOMER_DATA \
WHERE  STARS < 3 \
  AND  CLUB_STATUS = 'platinum';

CREATE TABLE RATINGS_BY_CLUB_STATUS AS \
SELECT CLUB_STATUS, COUNT(*) AS RATING_COUNT \
FROM RATINGS_WITH_CUSTOMER_DATA \
     WINDOW TUMBLING (SIZE 1 MINUTES) \
GROUP BY CLUB_STATUS;