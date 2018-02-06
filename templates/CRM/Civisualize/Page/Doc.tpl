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
<div class="alert alert-danger" role="alert">
  <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
  <span class="sr-only">Error:</span>
To add it, create a <a href="https://github.com/{$github}/new/master/{$path}?filename={$mdfile}">{$mdfile}</a> and write the help you want (in markdown format).
</div>
{/if}
<div>&nbsp;</div><div class="small pull-right">file: <a href="https://github.com/{$github}/blob/master/{$path}{$mdfile}">{$mdfile}</a></div>
