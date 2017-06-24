

function createBarChart(exerciseData) {

  var widthScale = d3.scaleLinear()
                     .domain([0, 100])
                     .range([0, 500]);

  var colorScale = d3.scaleLinear()
                     .domain([0, 100])
                     .range(["blue", "red"]);

  var axis = d3.axisBottom()
               .scale(widthScale);

  var canvas = d3.select('#last-try-d3')
                 .append('svg')
                 .attr('width', 500)
                 .attr('height', 1500)
                 .append('g')
                 .attr('transform', 'translate(20, 0)');

  canvas.selectAll('rect')
    .data(exerciseData)
    .enter()
      .append('rect')
      .attr('width', function(d) {return widthScale(d.wpm)})
      .attr('height', 50)
      .attr('fill', function(d) {return colorScale(d.wpm)})
      .attr('y', function(d, i) { return i * 100; })
      .attr('transform', 'translate(175, 0)');

  canvas.selectAll("text")
    .data(exerciseData)
    .enter()
      .append("text")
      .attr("class", "label")
      .attr('y', function(d, i) {return (i - 1) * 100 + 125;})
      .text(function(d) {return d.datetime.toLocaleString();})

  canvas.append('g')
        .attr('transform', 'translate(0, 400)')
        .call(axis)
}
