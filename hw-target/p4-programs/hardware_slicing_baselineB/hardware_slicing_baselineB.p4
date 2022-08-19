#include <core.p4>
#include <tna.p4>

#include "headers.p4"
#include "common.p4"

#include "customerB.p4"

Pipeline(EmptyIngressParser(),
         EmptyIngress(),
         EmptyIngressDeparser(),
         EmptyEgressParser(),
         EmptyEgress(),
         EmptyEgressDeparser()) CustomerAEmptyPipeline;

Pipeline(CustomerBIngressParser(),
         CustomerBIngress(),
         CustomerBIngressDeparser(),
         EmptyEgressParser(),
         EmptyEgress(),
         EmptyEgressDeparser()) CustomerB;

Pipeline(EmptyIngressParser(),
         EmptyIngress(),
         EmptyIngressDeparser(),
         EmptyEgressParser(),
         EmptyEgress(),
         EmptyEgressDeparser()) FirstEmptyPipeline;

Pipeline(EmptyIngressParser(),
         EmptyIngress(),
         EmptyIngressDeparser(),
         EmptyEgressParser(),
         EmptyEgress(),
         EmptyEgressDeparser()) SecondEmptyPipeline;

Switch(FirstEmptyPipeline, CustomerAEmptyPipeline, CustomerB, SecondEmptyPipeline) main;
