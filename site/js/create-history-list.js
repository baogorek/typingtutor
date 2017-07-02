function createHistoryList(exerciseInfo) {
  // Creates html list of previous activities organized by repo, file, and group
  var myList = d3.select("#history")
    .append("ul");

  myList.selectAll("li")
    .data(Object.keys(exerciseInfo))
    .enter()
      .append("li")
      .text(function(repo) {return repo}) // prints repo
        .append("ul")
        .selectAll("li")
        .data(function(repo) {
          my_array = [];
          Object.keys(exerciseInfo[repo]).forEach(function(element) {
            my_array.push({'repo':repo, 'file':element});
            });
          return my_array;
        })
          .enter()
          .append("li")
          .text(function(d) {return d.file;})
            .append("ul")
            .selectAll("li")
            .data(function(obj) {
              my_array = [];
              Object.keys(exerciseInfo[obj.repo][obj.file]).forEach(
                function(element) {
                  my_array.push({'repo':obj.repo, 'file':obj.file,
                                 'group':element})
                });
              return my_array;
            })
            .enter()
              .append("li")
              .text(function(d) {return d.group})
                .append("ul")
                .selectAll("li")
                .data(function(obj) {
                   return exerciseInfo[obj.repo][obj.file][obj.group]
                          .sort(dateSort)
                })
                .enter()
                  .append("li")
                  .text(function(d) {return d.datetime.toLocaleString() + ': ' +
                                            Math.round(d.wpm);})
}
