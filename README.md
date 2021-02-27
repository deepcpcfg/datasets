# Contents
This repository contains supplementary materials for the ICDAR submission *DeepCPCFG: Deep Learning and Context Free Grammars for End-to-End Information Extraction*

There are three sets of materials.
1. RVL-CDIP [link](https://www.cs.cmu.edu/~aharley/rvl-cdip/):
   * PDFs of the invoices.
   * OCRed bounding boxes.
   * Annotations for the invoices extracted from relational records.
   * The inference output of DeepCPCFG.
   * Results for each invoice using the Hierarchical Edit Distance (**HED**) metric.
2. CORD receipts [link](https://github.com/clovaai/cord):
   * OCRed bounding boxes.
   * Annotations converted from hand-annotations and represented as relational records.
   * Inference output of DeepCPCFG.
   * Results for each receipt based on the following metrics
     * SPADE metric, our interpretation and implementation of the metric used in *Spatial Dependency Parsing for Semi-Structured Document Information Extraction*.
     * HED metric
3. Code implementing the Hierarchical Edit Distance (HED) metric.

# Instructions for using the hed.jl
`hed.jl` is a self-contained file that implements Hierarchical Edit Distance (**HED**) metric for comparing two files representing the output/annotation of a hierarchical document.

1. Download and install [Julia](https://julialang.org/downloads/)
2. Install packages `ArgParse` and `JSON` in [Julia Built-in Package Manager](https://docs.julialang.org/en/v1/stdlib/Pkg/)
3. Try to run hed.jl as follows
```
$ julia hed.jl --help
```
You should see the following printout on your terminal prompt.
```
usage: hed.jl [--str-func STR-FUNC] [-h] prediction groundTruth

positional arguments:
  prediction           the .json file containing the prediction
  groundTruth          the .json file containing the ground truth

optional arguments:
  --str-func STR-FUNC  function on string: choose "split" (word-based)
                       or "identity" (character-based) (default:
                       "identity")
  -h, --help           show this help message and exit
```
4. If you see above printout, then continue as follows, 
```
$ julia hed.jl rvl-cdip/predictions/json/0060087309.json rvl-cdip/annotations/0060087309.json
```
5. Then you will get the following output, or see [hed_sample_output.txt](hed_sample_output.txt).
```
(long output detailing the exact calculations for each element in the prediction)

TP = 90, FP = 14, FN = 18, Precision = 0.8654, Recall = 0.8333, F₁ = 0.8491
```
6. To get precision and recall for the entire corpus, calculate HED for every pair of prediction/annotation, sum up the respective true positives, false positives and false negatives, then obtain the precision and recall using the aggregated counts.

## References
1. A. W. Harley, A. Ufkes, K. G. Derpanis, "Evaluation of Deep Convolutional Nets for Document Image Classification and Retrieval," in ICDAR, 2015.
2. S. Park, S. Shin, B. Lee, J. Lee, J. Surh, M. Seo, H. Lee, "CORD: A Consolidated Receipt Dataset for Post-OCR Parsing," in Document Intelligence Workshop NeurIPS, 2019.
3. W. Hwang, J. Yim, S. Park, S. Yang, M. Seo, "Spatial Dependency Parsing for Semi-Structured Document Information Extraction," in ArXiv, 2020.
