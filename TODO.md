# 

apply istio-base > istiod > istio-ingress in order - the admission webhook must be ready before we create the gateway pod.

- chart values cannot be override - it needs to be patched. https://github.com/kubernetes-sigs/kustomize/issues/4658
- pre-commit hook to lint kustomize
- scripts to boilerplate new modules
