function dateSort(a, b) {
  return Math.sign(2 * (a.datetime.getTime() < b.datetime.getTime()) - 1);
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
