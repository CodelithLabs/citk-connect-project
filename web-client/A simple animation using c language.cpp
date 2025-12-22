<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Simple Ship Animation</title>
<style>
  body {
    margin: 0;
    overflow: hidden;
    background: skyblue;
  }

  /* Ocean */
  .ocean {
    position: absolute;
    bottom: 0;
    width: 100%;
    height: 40%;
    background: linear-gradient(#1e90ff, #0047ab);
  }

  /* Ship container */
  .ship {
    position: absolute;
    bottom: 25%;
    left: -200px;
    width: 200px;
    height: 100px;
    animation: sail 10s linear infinite, float 2s ease-in-out infinite;
  }

  /* Ship body */
  .hull {
    position: absolute;
    bottom: 0;
    width: 200px;
    height: 40px;
    background: brown;
    border-radius: 0 0 30px 30px;
  }

  /* Mast */
  .mast {
    position: absolute;
    bottom: 40px;
    left: 95px;
    width: 6px;
    height: 60px;
    background: #333;
  }

  /* Sail */
  .sail {
    position: absolute;
    bottom: 40px;
    left: 100px;
    width: 0;
    height: 0;
    border-top: 50px solid transparent;
    border-bottom: 0 solid transparent;
    border-left: 70px solid white;
  }

  /* Animations */
  @keyframes sail {
    from {
      left: -200px;
    }
    to {
      left: 100%;
    }
  }

  @keyframes float {
    0%, 100% {
      transform: translateY(0);
    }
    50% {
      transform: translateY(-10px);
    }
  }
</style>
</head>
<body>

<div class="ship">
  <div class="mast"></div>
  <div class="sail"></div>
  <div class="hull"></div>
</div>

<div class="ocean"></div>

</body>
</html>
