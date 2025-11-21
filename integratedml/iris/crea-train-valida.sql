-- AutoML
-- We have our training data and our test data, we create our model. To do this, we will access the SQL screen of our IRIS (System Explorer --> SQL) from the MLTEST namespace and execute the following commands:

CREATE MODEL StayModel PREDICTING (Stay) FROM MLTEST_Data.EpisodeTrain

-- In this query we are creating a prediction model called StayModel that will predict the value of the Stay column of our table with training episodes. The stay column did not come in our CSV but we have calculated it in the BP in charge of transforming the CSV record.
-- Next we proceed to train the model:

TRAIN MODEL StayModel

-- This instruction will take a while but once the training is complete we can validate the model with our test data by running the following instruction:

VALIDATE MODEL StayModel FROM MLTEST_Data.Episode

-- This query will calculate how approximate our estimates are. As you can imagine with the data we have, these will not be exactly to get excited about. You can view the result of the validation with the following query:

SELECT * FROM INFORMATION_SCHEMA.ML_VALIDATION_METRICS 
WHERE MODEL_NAME='StayModel'

--From the statistics obtained we can see that the model used by AutoML is a classification model instead of a regression model. Let us explain what the results obtained mean(thank you @Yuri Marx for your article!):
--Precision: it is calculated by dividing the number of true positives by the number of predicted positives (sum of true positives and false positives).
--Recall: It is calculated by dividing the number of true positives by the number of true positives (sum of true positives and false negatives).
--F-Measure: calculated by the following expression: F = 2 * (Precision * Recall) / (Precision + Recall)
--Accuracy: calculated by dividing the number of true positives and true negatives by the total number of rows (sum of true positives, false positives, true negatives, and false negatives) of the entire data set.
--With this explanation we can already understand how good the generated model is:

--As you can see, in general numbers our model is quite bad, we barely reached 35% hits, if we go into more detail we see that for short stays the accuracy is between 35% and 60%, so we would surely need to expand the data that we have with information about possible pathologies that the patient may have and the triage regarding the fracture.

--Since we do not have these data that would refine our model much more, we are going to imagine that what we have is more than enough for our objective, so we can start feeding our production with ADT_A01 patient admission messages and we will see the predictions we obtain. .

