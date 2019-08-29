# This is the file that implements a flask server to do inferences. It's the file that you will modify to
# implement the scoring for your own algorithm.

from __future__ import print_function

import logging
import os

import flask
import numpy as np
import torch

model_path = os.environ.get('MODEL_PATH')

# A singleton for holding the model. This simply loads the model and holds it.
# It has a predict function that does a prediction based on the model and the input data.


class ScoringService(object):
    model = None                # Where we keep the model when it's loaded

    @classmethod
    def get_model(cls):
        """Get the model object for this instance, loading it if it's not already loaded."""
        if cls.model is None:
            # with open(model_path, 'rb') as inp:
            cls.model = torch.load(model_path)
        return cls.model

    @classmethod
    def predict(cls, input):
        """For the input, do the predictions and return them.

        Args:
            input (a pandas dataframe): The data on which to do the predictions. There will be
                one prediction per row in the dataframe"""
        clf = cls.get_model()
        return clf.predict(input)


# The flask app for serving predictions
app = flask.Flask(__name__)


@app.route('/ping', methods=['GET'])
def ping():
    """Determine if the container is working and healthy. In this sample container, we declare
    it healthy if we can load the model successfully."""
    health = ScoringService.get_model() is not None  # You can insert a health check here

    status = 200 if health else 404
    return flask.Response(response='\n', status=status, mimetype='application/json')


@app.route('/invocations', methods=['POST'])
def transformation():
    """Do an inference on a single batch of data.
    """
    data = None
    data = flask.request.get_json(force=True)
    logging.error("dataa")
    logging.error(data)


    # Do the prediction
    predictions = ScoringService.predict(np.array([data['userid']]))[:10]  #data)

    p = np.array2string(predictions, precision=2, separator=',', suppress_small=True)
    return flask.Response(response=p, status=200, mimetype='text/plain')
