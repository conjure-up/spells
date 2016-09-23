# Elasticsearch, Logstash and Kibana

The Elastic Stack — that's Elasticsearch, Logstash, Kibana — are open
source projects that help you take data from any source, any format and search,
analyze, and visualize it in real time.

**Elasticsearch** is a distributed, open source search and analytics engine,
designed for horizontal scalability, reliability, and easy management. It
combines the speed of search with the power of analytics via a sophisticated,
developer-friendly query language covering structured, unstructured, and
time-series data.

**Logstash** is a flexible, open source data collection, enrichment, and
transportation pipeline. With connectors to common infrastructure for easy
integration, Logstash is designed to efficiently process a growing list of log,
event, and unstructured data sources for distribution into a variety of outputs,
including Elasticsearch.

**Kibana** is an open source data visualization platform that allows you to
interact with your data through stunning, powerful graphics. From histograms to
geomaps, Kibana brings your data to life with visuals that can be combined into
custom dashboards that help you share insights from your data far and wide.


This bundle is a 4 node cluster designed to scale out.
Built around Elastic components, it contains:

- 1 Logstash unit (minimum mem=2GB)
- 2 Elasticsearch units
- 1 Kibana unit
