<?php
$validated="not tested";
$clientmac="";
$clientmac=$_GET['mac'];
$home=str_replace("fas.php","",$_SERVER['SCRIPT_NAME']);
$users=$_SERVER['DOCUMENT_ROOT'].$home."users.dat";

if (file_exists($users))//read the file line by line
{
$handle=fopen($users,'r');

while(! feof($handle))
{
$line=fgets($handle);
//shell_exec('sudo ndsctl auth f4:96:34:ea:f2:63');
if($clientmac==$line){$validated="yes"; break;}
}//end while not eof
if($validated!="yes"){$validated="no";}
fclose($handle);
}//end read the file line by line

if($validated=="yes"){
echo "do not redirect";
}

if($validated=="yes"){
echo "redirect to splash page";
}



?>



