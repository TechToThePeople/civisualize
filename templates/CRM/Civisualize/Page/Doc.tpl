<textarea id="md" class="hidden">
{$md}
</textarea>
{literal}
<script>
jQuery(function($){
  var md=$("#md").val();
  $("#content").html(marked(md));
});
</script>
{/literal}
<div id="content">

</div>
