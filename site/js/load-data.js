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

      var typingData; // for debugging help
      var dbRefObject = firebase.database().ref();
      dbRefObject.on('value', fillInPage);

      } else { // user needs to sign in
      window.location = "https://baogorek.github.io/typingtutor/"
    }
  });
};

function fillInPage(snapshot) {
  var typingData;

  if (snapshot.val()['user_info']) {
    typingData = snapshot.val()['user_info'][user.uid];
  }
  
  if (typingData) {
    var timestamps = Object.keys(typingData).sort().reverse();
    var last_obj = typingData[timestamps[0]];
    var timeLastEx = new Date(parseInt(timestamps[0].substring(1)));
    var lastTryMsg = 'You last practiced on repo <b>' +
      typingData[timestamps[0]]['repo'] + '</b> with file <b>' +
      typingData[timestamps[0]]['r_file'] + '</b> and expression group ' +
      '<i>' + typingData[timestamps[0]]['expression_group'] + '</i>. ' +
      'Your score was <b>' + Math.round(typingData[timestamps[0]]['wpm']) +
      '</b> words per minute!';
    
    document.getElementById('last-try').innerHTML = lastTryMsg + '\n\n';
    document.getElementById('last-try-d3').innerHTML = '';
    
    var exerciseInfo = transpose(typingData); 
    
    var fileData = exerciseInfo[last_obj.repo][last_obj.r_file];
    var exerciseData = fileData[last_obj.expression_group];
    exerciseData.sort(dateSort);
    createBarChart(exerciseData);
    
    document.getElementById('history').innerHTML = "";
    createHistoryList(exerciseInfo);
  } else {
    lastTryMsg = 'No data yet. Open R and play a round of typingtutor!'
    document.getElementById('last-try').innerHTML = lastTryMsg;
    document.getElementById('history').innerHTML = lastTryMsg;
  }
}
