var config = {
  apiKey: "AIzaSyDFLZi6KGXURw8nibcJhGhN23-4vbMNV24",
  authDomain: "typingtutor-9f7e9.firebaseapp.com",
  databaseURL: "https://typingtutor-9f7e9.firebaseio.com",
  projectId: "typingtutor-9f7e9",
  storageBucket: "typingtutor-9f7e9.appspot.com",
  messagingSenderId: "736144011972"
};

firebase.initializeApp(config);

initApp = function() {

  document.getElementById('firebase-token').style.display = 'none';
  firebase.auth().onAuthStateChanged(function(user) {
    if (user) {

      document.getElementById('welcome').textContent =
        'Welcome to typingtutor, ' + user.displayName + '!';

      var dbRefObject = firebase.database().ref()
                          .child("user_info/" + user.uid);
      var typingData;

      dbRefObject.on('value',
        function(snapshot) {

        typingData = snapshot.val();
        var last_obj = typingData[timestamps[0]];

        var timestamps = Object.keys(typingData).sort().reverse();
        var timeLastEx = new Date(parseInt(timestamps[0].substring(1)));
        var lastTryMsg = 'You last practiced typing the expression group <i>' +
          typingData[timestamps[0]]['expression_group'] + '</i> from file <b>' +
          typingData[timestamps[0]]['r_file'] + '</b> within repo <b>' +
          typingData[timestamps[0]]['repo'] + '</b>. Your score was <b>' +
          typingData[timestamps[0]]['wpm'] + '</b> words per minute!'

        document.getElementById('last-try').innerHTML = lastTryMsg + '\n\n';
        document.getElementById('last-try-d3').innerHTML = '';

        var exerciseInfo = transpose(typingData); 

        var fileData = exerciseInfo[last_obj.repo][last_obj.r_file];
        var exerciseData = fileData[last_obj.expression_group];
        createBarChart(exerciseData)

        document.getElementById('history').innerHTML = "";
        createHistoryList(exerciseInfo);
      }); // end dbRefObject.on
    } else { // user needs to sign in
      window.location = "https://baogorek.github.io/typingtutor/"
    }
  }); // onAuthStateChanged
};


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
                          .reverse();
                })
                .enter()
                  .append("li")
                  .text(function(d) {return d.datetime.toLocaleString() + ': ' +
                                            Math.round(d.wpm);})

}

function transpose(typingData) {
  // turns a timestamp-based key structure into a exercise-level structure 
  var exerciseInfo = {};
  Object.entries(typingData).forEach(([key, value]) => {

    if (value['repo'] && value['r_file'] && value['expression_group']) {
      if (!exerciseInfo[value['repo']]) {
        exerciseInfo[value['repo']] = {};
      } 
      if (!exerciseInfo[value['repo']][value['r_file']]) {
        exerciseInfo[value['repo']][value['r_file']] = {};
      }
      var new_key = value['expression_group'];
      var new_value ={};
      new_value["datetime"] = new Date(parseInt(key.substring(1)));
      new_value["wpm"] = value["wpm"];

      if (exerciseInfo[value['repo']][value['r_file']][new_key]) {
        exerciseInfo[value['repo']][value['r_file']][new_key] =
          exerciseInfo[value['repo']][value['r_file']][new_key]
            .concat(new_value);
      } else {
        exerciseInfo[value['repo']][value['r_file']][new_key] = [new_value];
      }
    }
  });
  return exerciseInfo;
};

function copyToClipboard(text) {
    window.prompt("Copy to clipboard: Ctrl+C, Enter", text);
};

function refreshToken() {
 firebase.auth().onAuthStateChanged(function(user) {
    if (user) {
      user.getToken().then(function(accessToken) {
        //document.getElementById('firebase-token').textContent = accessToken;
        copyToClipboard("{\"token\":\"" + accessToken +
        "\", \"userid\":\"" + firebase.auth().currentUser.uid + "\"}")
      });
    };
  });
};
