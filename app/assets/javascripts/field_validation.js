

$(document).ready(function(){
		
	$('#first_name').focusin(function() { 
	  $('#fname').html(''); 
	});
	
	
	$('#last_name').focusin(function() { 
	  $('#lname').html(''); 
	});
	
	
	$('#title').focusin(function() { 
	  $('#tt').html(''); 
	});
	
	
	$('#company_name').focusin(function() { 
	  $('#comp_name').html(''); 
	});
	
	
	$('#company_address').focusin(function() { 
	  $('#comp_add').html(''); 
	});
	
	
	$('#zip').focusin(function() { 
	  $('#zp').html(''); 
	});
	
	
	$('#city').focusin(function() { 
	  $('#cty').html(''); 
	});
	
	
	$('#mobile_phone').focusin(function() { 
	  $('#mphone').html(''); 
	});
	
	
	$('#office_phone').focusin(function() { 
	  $('#ophone').html(''); 
	});

   $('#company_email_id').focusin(function() { 
	  $('#comp_id').html(''); 
	});

});

function formValidation()
{

 var flag=0;
 
	if ($('#first_name').val() == '' || $('#first_name').val() == null)
	{
		$('#fname').html("First name can't be blank.");
		
		flag=1;
	}
	
	else
	{
		$('#fname').html("");
	}
	
	if ($('#last_name').val() == '' || $('#last_name').val() == null)
	{
		$('#lname').html("Last name can't be blank.");
		
		flag=1;
	}
	
	else
	{
		$('#lname').html("");
	}
	
	if ($('#title').val() == '' || $('#title').val() == null)
	{
		$('#tt').html("Title can't be blank.");
		
		flag=1;
	}
	
	else
	{
		$('#tt').html("");
	}
   	
	if ($('#company_name').val() == '' || $('#company_name').val() == null)
	{
		$('#comp_name').html("Company name can't be blank.");
		
		flag=1;
	}
	
	else
	{
		$('#comp_name').html("");
	}
	
	if ($('#company_address').val() == '' || $('#company_address').val() == null)
	{
		$('#comp_add').html("Company address can't be blank.");
		
		flag=1;
	}
	
	else
	{
		$('#comp_add').html("");
	}
		
	if ($('#zip').val() == '' || $('#zip').val() == null)
	{
		$('#zp').html("Zip name can't be blank.");
		
		flag=1;
	}
	
	else
	{
		$('#zp').html("");
	}
	
	if ($('#city').val() == '' || $('#city').val() == null)
	{
		$('#cty').html("City name can't be blank.");
		
		flag=1;
	}
	
	else
	{
		$('#cty').html("");
	}
	
	if ($('#mobile_phone').val() == '' || $('#mobile_phone').val() == null)
	{
		$('#mphone').html("Mobile phone name can't be blank.");
		
		flag=1;
	}
	
	else
	{
		$('#mphone').html("");
	}
	
	if ($('#office_phone').val() == '' || $('#office_phone').val() == null)
	{  
		$('#ophone').html("Office phone name can't be blank.");
		
		flag=1;
	}	
	
	if ($('#mobile_phone').val() == $('#office_phone').val())
	{
		$('#ophone').html("Phone number can't be same");
		$('#mphone').html("Phone number can't be same");
		$("#office_phone").val('');
		$("#mobile_phone").val('');
		flag=1;
	}	
	
	else
	{
		$('#ophone').html("");
	}
	
	if ($('#company_email_id').val() == '' || $('#company_email_id').val() == null)
	{
		$('#comp_id').html("Comapny email id name can't be blank.");
		
		flag=1;
	}
	
	else
	{
		$('#comp_id').html("");
	}
	
	

	
	
	if (flag==1)
	{
		return false;
		
	}
	else{		
		return true;
	}
      			
}

