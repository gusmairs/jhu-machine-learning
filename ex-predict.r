# Prediction model for an exercise data collection context. Creates a full 5-way
# classification model using SVM. The test data is not labeled, has case
# numbering instead to be used for turning in the predictions and getting a
# score out of the 20 cases included.

# %% Load libraries
#
library(caret, quietly = T)
library(e1071)
library(readr)
library(plyr)

# %% Load and subset data, eliminate the 100 out of 160 features with no data
#
path <- gsub('\n', '', readr::read_file('.data'))
train_raw <- read.csv(
    file.path(path, 'pml-training.csv'),
    header = TRUE, stringsAsFactors = FALSE,
    colClasses = c(label = 'factor')
)
train_raw <- rename(train_raw, c('X' = 'id', 'label' = 'label'))
test_raw <- read.csv(
    file.path(path, 'pml-testing.csv'),
    header = TRUE, stringsAsFactors = FALSE
)
test_raw <- rename(test_raw, c('X' = 'id'))
na_idx <- apply(train_raw, 2, function(x) mean(is.na(x) | x == '') > 0.9)
train_full <- train_raw[, !na_idx]  # 60 features
test <- test_raw[, !na_idx]
features <- features

# %% Set up train dataset and 5 small validation folds
#
set.seed(121)
train_idx <- caret::createDataPartition(train_full$id, p = 0.95, list = FALSE)
train <- train_full[train_idx, ]
validate <- train_full[-train_idx, ]
val_idx <- replicate(5, sample(validate$id, 20))
# for (i in 1:5) {
#     assign(
#         paste0('cv_', i),
#         validate[which(validate$id %in% val_idx[, i]), ]
#     )
# }
for (i in 1:5) {
    fold <- validate[which(validate$id %in% val_idx[, i]), ]
    do.call('<-', list(paste0('cv_', i), fold))
}

# %% Run PCA to transform train into matrix explaining 95% of the variance
#
pca_fit <- caret::preProcess(train[, features], method = 'pca', thresh = 0.95)
train_pca <- predict(pca_fit, train[, features])

# %% Fit an SVM model to the transformed matrix, get confusion matrix, accuracy
#
svm_fit <- e1071::svm(x = train_pca, y = train$label)
svm_predict <- predict(svm_fit, newdata = train_pca)
dim(svm_predict)


conf_matrix <- caret::confusionMatrix(svm_predict, train$label)
print(conf_matrix$table)
print(conf_matrix$overall['Accuracy'])

# %% Run the SVM prediction on 3 of the validation sets
#
cv_1_pca <- predict(pca_fit, cv_1[, features])
cv_1_pred <- predict(svm_fit, newdata = cv_1_pca)
acc_1 <- confusionMatrix(cv_1_pred, cv_1$label)$overall['Accuracy']

cv_2_pca <- predict(pca_fit, cv_2[, features])
cv_2_pred <- predict(svm_fit, newdata = cv_2_pca)
acc_2 <- confusionMatrix(cv_2_pred, cv_2$label)$overall['Accuracy']

cv_3_pca <- predict(pca_fit, cv_3[, features])
cv_3_pred <- predict(svm_fit, newdata = cv_3_pca)
acc_3 <- confusionMatrix(cv_3_pred, cv_3$label)$overall['Accuracy']

cbind(acc_1, acc_2, acc_3)

# %% Transform the test sample and run the model to predict final
#
tst_pca <- predict(pca_fit, tst[, features])
tst_pred <- predict(svm_fit, newdata = tst_pca)
tst_pred