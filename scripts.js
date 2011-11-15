
function draw_data(data, curr)
{
	var canvas = document.getElementById('graph');
	var ctx = canvas.getContext('2d');
	var width = canvas.parentNode.offsetWidth;
	var height = canvas.parentNode.offsetHeight;
	var unit_w = 5;
	ctx.canvas.width = width;

	ctx.beginPath();
	ctx.rect(0, 0, width, height);
	ctx.fillStyle = "rgb(255,255,255)";
	ctx.fill();

	data = data.filter(function(x) {
		return x[0] > curr - width/unit_w - 1;
	});

	var max = data.reduce(function(a, b) {
		var sum = Number(b[1]) + Number(b[2]);
		return a > sum ? a : sum;
	}, 0);

	if (max == 0) return;

	var datah = {};
	for (var i=0; i<data.length; i++) {
		datah[data[i][0]] = [data[i][1], data[i][2]];
	}

	for (var i=0; i<width/unit_w+1; i++) {
		var acc = datah[curr-i] ? datah[curr-i][0] : 0;
		var rej = datah[curr-i] ? datah[curr-i][1] : 0;

		var rejh = Math.ceil(height*rej/max);
		var acch = Math.ceil(height*acc/max);

		ctx.beginPath();
		ctx.rect(width-unit_w-unit_w*i, height-acch, unit_w, acch);
		ctx.fillStyle = "rgb(0,255,0)";
		ctx.fill();

		ctx.beginPath();
		ctx.rect(width-unit_w-unit_w*i, height-rejh-acch, unit_w, rejh);
		ctx.fillStyle = "rgb(255,0,0)";
		ctx.fill();
	}

	ctx.beginPath();
	ctx.rect(0, 0, width, height);
	ctx.lineWidth = 1;

	for (var i=0; i<width/unit_w+1; i+=30) {
		ctx.moveTo(width-unit_w*i-0.5, 0);
		ctx.lineTo(width-unit_w*i-0.5, height);
	}

	ctx.strokeStyle = "rgba(0,0,0,0.2)";
	ctx.stroke();
}

