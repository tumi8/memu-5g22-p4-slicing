#include <core.p4>
#include <tna.p4>

#include "headers.p4"
#include "common.p4"

#include "customerA.p4"

Pipeline(CustomerAIngressParser(),
         CustomerAIngress(),
         CustomerAIngressDeparser(),
         EmptyEgressParser(),
         EmptyEgress(),
         EmptyEgressDeparser()) CustomerA;

Pipeline(EmptyIngressParser(),
         EmptyIngress(),
         EmptyIngressDeparser(),
         EmptyEgressParser(),
         EmptyEgress(),
         EmptyEgressDeparser()) CustomerBEmptyPipeline;

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

Switch(FirstEmptyPipeline, CustomerA, CustomerBEmptyPipeline, SecondEmptyPipeline) main;
