<textarea id="md" class="hidden">
{$md}
</textarea>
<script>
var error="{$error}";
{literal}
jQuery(function($){
  var md=$("#md").val();
  $("#content").html(marked(md));
});
</script>
{/literal}
<div id="content">

</div>
{if $error}
<div>
To add it, create a {$mdfile} and write the help you want (in markdown format).
</div>
{/if}
<div>&nbsp;</div><div class="small pull-right">file: {$mdfile}</div>
