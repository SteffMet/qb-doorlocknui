$('document').ready(function() {
    $('.form').hide()

    document.onkeydown = function (data) {
        if (data.which == 27) {
            $.post('https://qb-doorlocknui/close');
        }
    };

    window.addEventListener("message", function (event) {

        if (event.data.type == "newDoorSetup") {
            event.data.enable ? $('.form').show() : $('.form').hide();

            $("#newDoor").submit(function(event) {                       
                $.post('https://qb-doorlocknui/newDoor', JSON.stringify({
                    doorname: $("#doorname").val(),
                    doortype: $("#doortype").val(),
                    doorlocked: $("input[type='radio'][name='doorlocked']:checked").val(),
                    job1: $("#job1").val(),
                    job2: $("#job2").val(),
                    job3: $("#job3").val(),
                    job4: $("#job4").val(),
                    item: $("#item").val()
                }));
            });
		}

        if (event.data.action == 'audio') {
            var sound = document.querySelector('#sounds');
            var volume = (event.data.audio['volume'] / 10 ) * event.data.sfx

            if (event.data.distance !== 0) {
                var volume = volume / event.data.distance
            }
            sound.setAttribute('src', 'sounds/' + event.data.audio['file']);
            sound.volume = volume;
			sound.play();
        }
        else
        {
            if (event.data.text == "Locked") {
                event.data.text = '<i style="color:orange" class="fas fa-lock"></i>'
            } else if (event.data.text == "Unlocked") {
                event.data.text = '<i style="color:limegreen" class="fas fa-unlock"></i>'
            } else if (event.data.text == "Locking") {
                event.data.text = '<i style="color:orange" class="fas fa-lock"><br>Locking</i>'
            }

            event.x = (event.data.x * 100) + '%';
            event.y = (event.data.y * 100) + '%';
            if (event.data.text == undefined) {event.data.action = "hide"}
            $('.doorlock').html(event.data.text);
            $('.doorlock').css({ "left": event.x, "top": event.y });

            if (event.data.action == "display") {
                $('.doorlock').show()
                $('.container').show()
            } else if (event.data.action == "hide") {
                $('.doorlock').html('');
                $('.doorlock').hide()
                $('.container').hide()
            }
        }
    })
});
