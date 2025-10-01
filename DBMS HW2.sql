

set SQL_SAFE_UPDATES=0; 
set FOREIGN_KEY_CHECKS=0; 

use homework_two; 

/*
Average food price at each restaurant 

This query works by selecting name and food price. We are able to 
attain those values by joining the foodIDs from foods and serves, which
would match columns only where the food IDs match. Finally, we join 
the restaurant IDs where they match the serve IDs, because we are 
only interested in restaurants that serve their own food. We also
Group by the name
*/

SELECT 
    r.`name`, AVG(price)
FROM
    serves s
        JOIN
    foods f ON s.foodID = f.foodID
        JOIN
    restaurants r ON r.restID = s.restID
GROUP BY r.`name`;
    
    
    /*
    Maximum food price at each restaurant:
    
    We select name and max price. We get it from serves, and
    we want to join serves to the food associated with each restaurant. Additionally, we 
    join restaurant as well, because we want the restaurant associated with their food. 
    Since we used the MAX function, we will retrieve the max price, and it will be grouped
    by restaurant name. 
    */
    
    SELECT
		r.`name`, MAX(price)
	FROM 
		serves s
	JOIN
		foods f ON s.foodID = f.foodID
	JOIN
		restaurants r ON r.restID = s.restID
	GROUP BY r.`name`;
    
    /*
    Count of different food types at each restaurant
    Here we select restaurant name and the count of distinct food types. The 
    distinct keyword makes it so that it will only contribute to the count if it is
    unique type. We select it from serves, and we want to join foods with the restaurant
    associated with it again. We combine the tables by joining foods to the corresponding foodID
    in serves, and likewise with restaurants so there will only be foods and restaurants that 
    are associated, then group by name.
    */
   SELECT
		r.`name`, count( distinct f.`type`)
	FROM
		serves s
	JOIN 
		foods f ON s.foodID = f.foodID
    JOIN
		restaurants r ON r.restID = s.restID
	GROUP BY r.`name`;
    
    -- Average price of foods by chef
    /*
    We select the chef name and average food prices for display. We go to the chefs table first, and 
    need to use joins to associate chefs with the restaurant at which they work using the corresponding chefID
    and restID in works. Next, we need to know what foods are served at each restaurant, so we combine
    restaurants and foods using the serves table, making sure the restID and foodID are matching.
    This
    */
    
SELECT 
    c.`name`, AVG(f.price)
FROM
    chefs c
		JOIN
    works w ON c.chefID = w.chefID
        JOIN
    restaurants r ON r.restID = w.restID
        JOIN
    serves s ON r.restID = s.restID
        JOIN
    foods f ON f.foodID = s.foodID
GROUP BY c.`name`;
		
        -- Find the Restaurant with the Highest Average Food Price 
        /*
        We select the restaurant name and average food price, and we make avg_price a variable. We use restaurants
        first, and join it to the corresponding foods using the serves table, because we only want foods that the 
        restaurant serves. Then we group by restaurant name, but since we care about the highest price, we want
        to order it by the avg_price. Since we want the highest average priced restaurant specifically, we limit
        the result to 1. 
        */
SELECT 
    r.`name`, AVG(f.price) as avg_price
FROM
    restaurants r
        JOIN
    serves s ON s.restID = r.restID
        JOIN
    foods f ON s.foodID = f.foodID
GROUP BY r.`name`
ORDER BY avg_price desc
limit 1;

/*
Extra Credit: Determine which chef has the highest average 
price of the foods served at the restaurants where they work.
 Include the chef’s name, the average food price, and the names
 of the restaurants where the chef works. Sort the  results by 
 the average food price in descending order
 */
 
 /*
 We select the average price, assign it to the variable avg_price, and each chef name. We need the last column
 to fill the requirement, but some chefs work at multiple restaurants and we can't cram two rows into one. Therefore
 instead of creating a whole new column we can just concatenate a column called restaurants onto the end, and use the 
 distinct keyword to avoid repeats. From there, we start with the chefs table and want to join them to the 
 restaurant that they work at using the works table, and we do this by making sure the chefID and restID
 match each other. next, we need to combine restaurants to the foods they serve using the serve table, and making
 sure the foodID and restID match. Finally, we group by chef name and order it by avg price with the keyword desc to 
 get the highest values on top. 
 */
 
SELECT 
    AVG(f.price) as avg_price,
    c.`name`,
    GROUP_CONCAT(DISTINCT r.`name`) Restaurants
FROM
    chefs c
        JOIN
    works w ON c.chefID = w.chefID
        JOIN
    restaurants r ON w.restID = r.restID
        JOIN
    serves s ON r.restID = s.restID
        JOIN
    foods f ON s.foodID = f.foodID
GROUP BY c.`name`
ORDER BY avg_price desc;
   


