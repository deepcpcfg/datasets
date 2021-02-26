# Contents
This repository contains supplementary materials for the ICDAR submission *DeepCPCFG: Deep Learning and Context Free Grammars for End-to-End Information Extraction*

There are three sets of materials.
1. RVL-CDIP:
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


## References
1. A. W. Harley, A. Ufkes, K. G. Derpanis, "Evaluation of Deep Convolutional Nets for Document Image Classification and Retrieval," in ICDAR, 2015.
2. S. Park, S. Shin, B. Lee, J. Lee, J. Surh, M. Seo, H. Lee, "CORD: A Consolidated Receipt Dataset for Post-OCR Parsing," in Document Intelligence Workshop NeurIPS, 2019.
3. W. Hwang, J. Yim, S. Park, S. Yang, M. Seo, "Spatial Dependency Parsing for Semi-Structured Document Information Extraction," in ArXiv, 2020.
