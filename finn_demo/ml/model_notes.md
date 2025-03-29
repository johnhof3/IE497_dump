# Model Outline

## Preprocessing
- don't use first and last 10 minuted of trading data
- time horizon 100
- delta t is defined by milliseconds in trading day/ average time to wait for mid price change
- I don't think we need to buffer like in paper
- winsorize the dependent variables
- MSE, SGD, and Adam optimizer, 10^-3 learning rate, 256 batch size for 50 epochs
- We want to use OF, not LOB, note this will use Petters model but only layers 

## Setup
- train a demo model, doesn't have to be accurate, then port it to hardware and get latency for predicting time horizons