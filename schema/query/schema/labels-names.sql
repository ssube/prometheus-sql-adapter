-- unique timeseries by time
SELECT COUNT(DISTINCT(labels->>'__name__')) FROM metric_labels;

-- by lid
SELECT COUNT(DISTINCT(lid)) FROM metric_labels;