# temps_record

Log every °C reading from `sensors` at a fixed interval, then print a per-sensor MIN / AVG / MAX table. The full log is kept as CSV.

## Requirements

lm-sensors.

## Use

```
chmod +x temps_record.sh
./temps_record.sh -i 1 -o run1.csv      # 1 s interval, custom output file
./temps_record.sh [-i sec] [-o file.csv] [command ...]
```

The CSV can be viewed as a colour-coded HTML table with [temps_view](https://github.com/bensantora/temps_view).

## License

MIT - see [LICENSE](LICENSE).
