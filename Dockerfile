################## MultiStage build ######################

################## Core ######################

FROM busybox AS buildcore

MAINTAINER Amanda Cooksey <amandamcooksey@gmail.com>

ARG IPR=5
ENV IPR $IPR
ARG IPRSCAN=5.36-75.0
ENV IPRSCAN $IPRSCAN

RUN mkdir -p /opt/interproscan/bin/blast/ncbi-blast-2.7.1+

RUN wget -O /opt/interproscan-core-$IPRSCAN.tar.gz ftp://ftp.ebi.ac.uk/pub/software/unix/iprscan/$IPR/$IPRSCAN/alt/interproscan-core-$IPRSCAN.tar.gz
RUN wget -O /opt/interproscan-core-$IPRSCAN.tar.gz.md5 ftp://ftp.ebi.ac.uk/pub/software/unix/iprscan/$IPR/$IPRSCAN/alt/interproscan-core-$IPRSCAN.tar.gz.md5


WORKDIR /opt

RUN md5sum -c interproscan-core-$IPRSCAN.tar.gz.md5

RUN  tar -pxvzf interproscan-core-$IPRSCAN.tar.gz \
    -C /opt/interproscan --strip-components=1 \
    && rm -f interproscan-core-$IPRSCAN.tar.gz interproscan-core-$IPRSCAN.tar.gz.md5


# Workaround bin/blast/ncbi-blast-2.7.1+/rpsblast: error while loading shared
# libraries: libgnutls.so.28: cannot open shared object file: No such file or 
# directory
RUN wget -O /opt/ncbi-blast-2.7.1+-x64-linux.tar.gz ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.7.1/ncbi-blast-2.7.1+-x64-linux.tar.gz
RUN tar xvf ncbi-blast-2.7.1+-x64-linux.tar.gz


# copy the new version to the binary folder
RUN cp /opt/ncbi-blast-2.7.1+/bin/rpsblast /opt/interproscan/bin/blast/ncbi-blast-2.7.1+/rpsblast



################## BASE IMAGE ######################

FROM ubuntu:16.04

MAINTAINER Amanda Cooksey <amandamcooksey@gmail.com>
LABEL  base_image="ubuntu:16.04" \
       software="interproscan" \
       software.version="5.36-75.0" \
       version="1" \
       about.summary="Scan sequences against the InterPro protein signature databases." \
       about.home="https://www.ebi.ac.uk/interpro/interproscan.html" \
       about.license="Apache-2.0" \
       about.license_file="https://github.com/ebi-pf-team/interproscan/blob/dev/LICENSE" \
       about.documentation="https://github.com/ebi-pf-team/interproscan/wiki" \
       about.tags="biology::nucleic, biology::protein, field::biology, field::biology:bioinformatics, interface::commandline, role::program,:biological-sequence" \
       extra.identifier.biotools="interproscan_4" \
       extra.binaries="interproscan.sh"


RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
        openjdk-8-jre   \
        build-essential \
        pkg-config      \
        python3         \
        bzip2           \
        ca-certificates && \
    apt-get clean && \
    apt-get purge && \
    rm -rf /var/lib/apt/lists/* /tmp/*

COPY --from=buildcore /opt/interproscan /opt/interproscan

WORKDIR /opt/interproscan

COPY ./splitfasta.pl /opt/interproscan
COPY ./iprs_wrapper.sh /opt/interproscan
COPY ./cyverse_parse_ips_xml.pl /opt/interproscan


ENTRYPOINT ["/bin/bash", "iprs_wrapper.sh"]
##################### INSTALLATION END #####################
