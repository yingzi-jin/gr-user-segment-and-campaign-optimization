#/usr/bin/env python
# -*- coding: utf-8 -*-

#######################################################
import Orange
#import pandas
#import numpy
import pickle
from myfunctions import *
#######################################################

def main():
     mdata = Orange.data.Table("./data/campaign_user_for_model.txt")
     sdata = Orange.data.Table("./data/campaign_user_for_score.txt")
     mpath, spath = "./model/model.dump", "./data/score.csv"

     classifier = build_model(data=mdata, path=mpath)
     df = score_prob(data=sdata, clf=classifier, path=spath)

def build_model(data,path):
     tree = Orange.classification.tree.TreeLearner(min_instance=5, max_depth=5, name="tree")
     forest = Orange.ensemble.forest.RandomForestLearner(base_learner=tree, trees=50, attributes=None, name="forest")
     logreg = Orange.classification.logreg.LogRegLearner(stepwise_lr=True, remove_singular=True, name="logreg")
     learners = [tree, logreg, forest]

     # Print evaluation info
     results = Orange.evaluation.testing.cross_validation(learners, data, folds=5)

     # print evaluation values
     print "Learner | CA | Brier | AUC"
     for i in range(len(learners)):
          print "%-8s %5.3f %5.3f %5.3f" % (
               learners[i].name,
               Orange.evaluation.scoring.CA(results)[i],
               Orange.evaluation.scoring.Brier_score(results)[i],
               Orange.evaluation.scoring.AUC(results)[i]
          )

     # Modelling
     # should have been choosen the best models..
     classifier = forest(data)

     # Save the Model
     # Cannot pickle.load on windows..
     pickle.dump(classifier, open(path, "w"))

     # Print the Model Info
     measure = Orange.ensemble.forest.ScoreFeature(base_learner=tree, trees=50, attributes=None)
     print "forest All importances:"
     for attr in data.domain.attributes:
          print "%15s: %6.3f" % (attr.name, measure(attr, data))

     #return
     return classifier

def score_prob(data, clf, path):
    score, prob = [],[]
    prob.append(["Prob(res=0)", "Prob(res=1)"]) #

    result_type = Orange.classification.Classifier.GetBoth

    #score: [[<orange.Value 'flag'='1'>, <0.428, 0.572>], [..],...]
    for inst in data:
        score.append(clf(inst, result_type))

    # prob :  [[0.42846283316612244, 0.5715371370315552], [],...] =>出力
    for i in range(len(score)):
        prob.append([score[i][1][0], score[i][1][1]])

    output_csv(prob,path)
     #df_prob = DataFrame(prob, columns=["Prob(res=0)", "Prob(res=1)"])
     #df_prob.to_csv(path, index=False, mode="w")

     #return
    #return df_prob

if __name__ == '__main__':
     main()
