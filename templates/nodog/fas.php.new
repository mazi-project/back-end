<?php
$validated="not tested";
$clientmac=$clientip=$redir=$tok=$authaction=$gatewayname="";
$clientmac=$_GET['mac'];
$clientip=$_GET['ip'];
$redir=$_GET['redir'];
$tok=$_GET['tok'];
$authaction=$_GET['authaction'];
$gatewayname=$_GET['gatewayname'];
$home=str_replace("fas.php","",$_SERVER['SCRIPT_NAME']);
$users=$_SERVER['DOCUMENT_ROOT'].$home."users.dat";


if (file_exists($users))//read the file line by line
{
$handle=fopen($users,'r');

while(! feof($handle))
{
$line=fgets($handle);
if($clientmac==$line){
$validated="yes"; 
shell_exec('sudo ndsctl auth f4:96:34:ea:f2:63');
break;
}
}//end while not eof
if($validated!="yes"){$validated="no";}
fclose($handle);
}//end read the file line by line

if($validated=="yes"){
echo "do not redirect";
}

if($validated=="no"){
echo "redirect to splash page";
header("Location: http://portal.mazizone.eu/nodog/splash.html?mac=$clientmac&ip=$clientip&redir=$redir&tok=$tok&authtarget=$authaction&gatewayname=$gatewayname");
//header("Location: http://portal.mazizone.eu/nodog/splash.html");
}



?>



