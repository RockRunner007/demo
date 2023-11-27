#!/usr/bin/env bash
cd src/ && \
docker run -v "$PWD":/var/task "public.ecr.aws/sam/build-python3.8" \
/bin/sh -c "pip install boto3[crt] -t python/lib/python3.8/site-packages; exit" && \
zip -r crtlibs.zip python > /dev/null

aws lambda publish-layer-version \
    --layer-name python38-crt --description "boto3 crt layer" \
    --zip-file fileb://crtlibs.zip --compatible-runtimes python3.8
