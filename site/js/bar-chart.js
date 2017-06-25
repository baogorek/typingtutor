

function createBarChart(exerciseData) {

  var n_bars = exerciseData.length;
  var bar_height = 35;
  var bar_dist = 15;
  var label_font_size = 18;
  var axis_space = 45; // Need a way to tie this to axis font
  var label_space = 175;
  var svg_width = 1000;
  var svg_height = (bar_height + bar_dist) * n_bars + bar_dist + axis_space


  var widthScale = d3.scaleLinear()
                     .domain([0, 100]) // wpm scale
                     .range([0, svg_width]); // pixel scale

  var colorScale = d3.scaleLinear()
                     .domain([0, 100])
                     .range(["blue", "red"]);

  var axis = d3.axisBottom()
               .scale(widthScale);
      
  var canvas = d3.select('#last-try-d3')
                 .append('svg')
                 .attr('width', svg_width)
                 .attr('height', svg_height)
                 .append('g')
                 .attr('transform', 'translate(20, 0)');

  canvas.selectAll('rect')
    .data(exerciseData)
    .enter()
      .append('rect')
      .attr('width', function(d) {return widthScale(d.wpm)})
      .attr('height', bar_height)
      .attr('fill', function(d) {return colorScale(d.wpm)})
      .attr('y', function(d, i) {return i * (bar_height + bar_dist)})
      .attr('transform', 'translate(' + label_space + ', 0)');

  canvas.selectAll("text")
    .data(exerciseData)
    .enter()
      .append("text")
      .attr("class", "label")
      .attr("font-size", label_font_size.toString())
      .attr('y', function(d, i) {return i * (bar_height + bar_dist) +
                                        bar_height / 2 +
                                        label_font_size / 2})
      .text(function(d) {return d.datetime.toLocaleString();})

  var axis_pos = (bar_height + bar_dist) * n_bars + bar_dist;
  canvas.append('g')
    .attr('transform', 'translate(' + label_space + ', ' + axis_pos + ')')
    .style("font", "16px times")
    .call(axis)

  canvas.append("text")
    .attr("font-size", label_font_size.toString())
    .attr("x", svg_width / 2)
    .attr("y", svg_height - label_font_size / 2)
    .style("text_anchor", "middle")
    .text("Words per Minute")

}
