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
      var exerciseInfo = {};

      dbRefObject.on('value',
        function(snapshot) {

          // data manipulation
          typingData = snapshot.val();
          Object.entries(typingData).forEach(([key, value]) => {

          if (value['r_file'] && value['expression_group']) {
            var new_key = value['r_file'] + ':' + value['expression_group'];
            var new_value ={};
            new_value["datetime"] = new Date(parseInt(key.substring(1)));
            new_value["wpm"] = value["wpm"];
            if (exerciseInfo[new_key]) {
              exerciseInfo[new_key] = exerciseInfo[new_key].concat(new_value);
            } else {
              exerciseInfo[new_key] = [new_value];
            }
          }
        });
        // End transpose object

        var timestamps = Object.keys(typingData).sort().reverse();
        var timeLastEx = new Date(parseInt(timestamps[0].substring(1)));
        var lastTry = 'The last time you played was on ' + timeLastEx +
          '<br/><br/> The file was ' +
                      typingData[timestamps[0]]['r_file'] +
                      '<br/><br/> The expression group played was ' +
                      typingData[timestamps[0]]['expression_group'] +
                      '\n with wpm: ' + typingData[timestamps[0]]['wpm'];

        var last_object = typingData[timestamps[0]];
        var last_key = last_object['r_file'] + ':' +
          last_object['expression_group'];

        document.getElementById('last-try').innerHTML = lastTry + '\n\n' +
          JSON.stringify(exerciseInfo[last_key]);
        document.getElementById('last-try-d3').innerHTML = '';
        
        var exerciseData = exerciseInfo[last_key];
        exerciseData.reverse() // So the most recent bar is first
        createBarChart(exerciseData)

        document.getElementById('history').innerHTML = "";
        var myList = d3.select("#history")
          .append("ul");

        myList.selectAll("li")
          .data(Object.keys(exerciseInfo))
          .enter()
            .append("li")
            .text(function(d) { return d;})
              .append("ul")
              .selectAll("li")
              .data(function(d) { return exerciseInfo[d] })
              .enter()
                .append("li")
                .text(function(d) { return d.datetime.toLocaleString() +
                                   ': ' + d.wpm.toString();} );
      }); // end dbRefObject.on
    } else { // user needs to sign in
      window.location = "https://baogorek.github.io/typingtutor/"
    }
  }); // onAuthStateChanged
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
