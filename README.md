# ML integration in OPM

Work based on Kerasify a small library for running trained Keras models from a C++ application. 

Design goals:

* Compatibility with image processing Sequential networks generated by Keras using Theano backend.
* CPU only, no GPU
* No external dependencies, standard library, C++11 features OK.
* Model stored on disk in binary format that can be quickly read.
* Model stored in memory in contiguous block for better cache performance.
* Doesn't throw exceptions, returns only bool on error.


# ML model using Keras

make_model_BCkrn.py:

```
from sklearn.preprocessing import MinMaxScaler
from sklearn.metrics import mean_squared_error
from keras.models import Sequential
from keras.layers import Dense
from numpy import asarray
from matplotlib import pyplot
import numpy as np
import pandas as pd
  
def computeBCKrn(satW, lambdaparam):
  Sn = 1.0 - satW;
  exponent = 2.0/lambdaparam + 1.0
  kr = Sn*Sn*(1. - pow(satW, exponent))
  return kr

sw = np.linspace(0, 1, 10001).reshape( (10001, 1) )

lambdaparam = 2

#BCKrw = computeBCKrw(sw, lambdaparam)
BCKrn = computeBCKrn(sw, lambdaparam)

# define the dataset
x = sw
# x = asarray([i for i in range(-50,51)])
y = np.array([BCKrn])

print(x.min(), x.max(), y.min(), y.max())
# reshape arrays into into rows and cols
x = x.reshape((len(x), 1))
y = y.reshape((10001, 1))
# separately scale the input and output variables
scale_x = MinMaxScaler()
x = scale_x.fit_transform(x)
scale_y = MinMaxScaler()
y = scale_y.fit_transform(y)
print(x.min(), x.max(), y.min(), y.max())
# design the neural network model
model = Sequential()
model.add(Dense(3, input_dim=1, activation='relu', kernel_initializer='he_uniform'))
# model.add(Dense(10, activation='relu', kernel_initializer='he_uniform'))
model.add(Dense(10, activation='relu', kernel_initializer='he_uniform'))
model.add(Dense(10, activation='relu', kernel_initializer='he_uniform'))
model.add(Dense(10, activation='relu', kernel_initializer='he_uniform'))
model.add(Dense(10, activation='relu', kernel_initializer='he_uniform'))
model.add(Dense(10, activation='relu', kernel_initializer='he_uniform'))
# model.add(Dense(1000, activation='relu', kernel_initializer='he_uniform'))

model.add(Dense(1))
# define the loss function and optimization algorithm
model.compile(loss='mse', optimizer='adam')
# ft the model on the training dataset
model.fit(x, y, epochs=1000, batch_size=100, verbose=0)
# make predictions for the input data
yhat = model.predict(x)
# inverse transforms
x_plot = scale_x.inverse_transform(x)
y_plot = scale_y.inverse_transform(y)
yhat_plot = scale_y.inverse_transform(yhat)
# report model error
print('MSE: %.3f' % mean_squared_error(y_plot, yhat_plot))
print(yhat_plot)
print('blah: %.3f' % mean_squared_error(y_plot, yhat_plot))

#save model
#from keras2cpp import export_model
#export_model(model, 'example.model')
from kerasify import export_model
export_model(model, 'example.modelBCkrn')

```

opm-common/opm/material/fluidmatrixinteractions/BrooksCorey.hpp:

```
#include "ml_tools/keras_model.h"
#include "ml_tools/keras_model.cc"

template <class Evaluation>
static Evaluation twoPhaseSatKrn(const Params& params, const Evaluation& Sw)
{
    assert(0.0 <= Sw && Sw <= 1.0);


    KerasModel model;
    // Beware of the correct path (we are working in opm-model/test in the current case)
    model.LoadModel("../../opm-common/opm/material/fluidmatrixinteractions/ml_tools/example.modelBCkrn");
    Tensor in{1};
    const Evaluation temp = Sw;
    in.data_ = {temp};
    // bba
    // Run prediction.
    Tensor out;
    model.Apply(&in, &out);
    //
    Scalar exponent = 2.0/params.lambda() + 1.0;
    const Evaluation Sn = 1.0 - Sw;
    auto exactsol = Sn*Sn*(1. - pow(Sw, exponent));

    Evaluation result= 0.0;

    if (out.data_[0].value() <= 1.e-50)
      result= exactsol;
    else if (out.data_[0].value() > 0.99) {
      result= exactsol;
    }
    else
      result=out.data_[0].value();

    return result;
}
```

# How to build 
To build the packages,
$ source dune_and_opm_in_macOS.bash

# How to run an example

To run the example, generate the example models and then run examples from opm-models :

```
Generate ml models and loading in opm-common

$ cd opm-common/opm/material/fluidmatrixinteractions/ml_tools/
$ python make_model_BCkrn.py
$ python make_model_BCkrw.py
$ python make_model_VGkrn.py
$ python make_model_VGkrw.py
$ cd ../../../../../
...

Run a practical example from opm-models

$ cd build/opm-models 
$ make lens_immiscible_ecfv_ad 

$ ./bin/lens_immiscible_ecfv_ad 



