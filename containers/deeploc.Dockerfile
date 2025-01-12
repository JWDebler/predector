ARG IMAGE="darcyabjones/base"
ARG FFINDEX_IMAGE

FROM "${FFINDEX_IMAGE}" as ffindex_builder

FROM "${IMAGE}" as deeploc_builder

ARG DEEPLOC_VERSION="1.0"
ARG DEEPLOC_PREFIX_ARG="/opt/deeploc/${DEEPLOC_VERSION}"
ARG DEEPLOC_TAR="sources/deeploc-1.0.All.tar.gz"
ENV DEEPLOC_PREFIX="${DEEPLOC_PREFIX_ARG}"
LABEL deeploc.version="${DEEPLOC_VERSION}"

ENV PATH="${DEEPLOC_PREFIX}/bin:${PATH}"
ENV LIBRARY_PATH="${DEEPLOC_PREFIX}/lib:${LIBRARY_PATH}"
ENV LD_LIBRARY_PATH="${DEEPLOC_PREFIX}/lib:${LD_LIBRARY_PATH}"
ENV PYTHONPATH="${DEEPLOC_PREFIX}/lib/python3.7/site-packages:${PYTHONPATH:-}"
COPY "${DEEPLOC_TAR}" /tmp/deeploc.tar.gz


ARG FFINDEX_TAG="0.9.9.9"
ARG FFINDEX_PREFIX_ARG="/opt/ffindex/${FFINDEX_VERSION}"
ENV FFINDEX_PREFIX="${FFINDEX_PREFIX_ARG}"
LABEL ffindex.version="${FFINDEX_VERSION}"

ENV LIBRARY_PATH="${FFINDEX_PREFIX}/lib:${LD_LIBRARY_PATH}"
ENV LD_LIBRARY_PATH="${LIBRARY_PATH}:${LD_LIBRARY_PATH}"
ENV CPATH="${FFINDEX_PREFIX}/include:${CPATH}"
ENV PATH="${FFINDEX_PREFIX}/bin:${PATH}"

COPY --from=ffindex_builder "${FFINDEX_PREFIX}" "${FFINDEX_PREFIX}"
COPY --from=ffindex_builder "${APT_REQUIREMENTS_FILE}" /build/apt/ffindex.txt


WORKDIR /tmp
RUN  set -eu \
  && DEBIAN_FRONTEND=noninteractive \
  && . /build/base.sh \
  && add_runtime_dep g++ python3 python3-pip python3-wheel python3-setuptools python3-numpy python3-scipy python3-theano python3-lasagne \
  && apt-get update \
  && apt_install_from_file "${APT_REQUIREMENTS_FILE}" \
  && apt_install_from_file /build/apt/*.txt \
  && apt-get autoremove \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && tar xf deeploc.tar.gz \
  && rm deeploc.tar.gz \
  && cd deeploc* \
  && sed -i '/install_requires=install_requires/d' setup.py \
  && python3 -m pip install --prefix="${DEEPLOC_PREFIX}" . \
  && rm -rf -- /tmp/deeploc* \
  && cat /build/apt/*.txt >> "${APT_REQUIREMENTS_FILE}"
