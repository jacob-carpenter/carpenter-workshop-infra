## Important Notes

- Avoid writing new READMEs or verbose comments on self-documenting code or features. We'll explicitely ask for documentation when needed.
- This terraform is intended to house core aws provisioning that is widely applicable. Avoid app specific infra construction here.
- We maintain a single shared kubernetes cluster with core capablities all managed here. We also maintain a shared common-app-library helm chart here, that other repo's apps may leverage for app specific helm charts.
- We are frugal in terms of infrastructure spend, so keep that in mind.
