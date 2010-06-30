# Global path for render_snippets
helpr_path <- NULL   

#' Helpr Documentation
#'
#' Execute to show documentation
#' @param installed use TRUE if the package is installed on from CRAN
helpr <- function(installed = TRUE) {
  if (installed) {
    path <- system.file(package = "helpr")
  } else {    
    path <- normalizePath(file.path(getwd(), "inst"))
  }
  helpr_path <<- path

  router <- Router$clone()

  # Show list of all packages on home page
  router$get("/index.html", function() {
    render_brew("index", helpr_home(), path = path)
  })

  # Use file in public, if present
  router$get("/*", function(splat) {
    static_file(file.path(path, "public", splat))
  })

  # Redirect old home location to new
  router$get("/doc/html/index.html", function() {
    redirect("/index.html")
  })

  router$get("/", function() {
    redirect("/index.html")
  })

  # If package path, missing trailing /, redirect
  router$get("/package/:package", function(package) {
    redirect(str_join("/package/", package, "/"))
  })

  # Package index page, list topics etc
  router$get("/package/:package/", function(package) {
    require(package, character.only = TRUE)
    render_brew("package", helpr_package(package), path = path)    
  })
  
  # Package Vignette
  router$get("/package/:package/vignette/:vignette", function(package, vignette) {
    require(package, character.only = TRUE)
    static_file(system.file("doc", str_join(vignette, ".pdf"), package = package))
  })

  # Package Demo
  router$get("/package/:package/demo/:demo", function(package, demo) {
    require(package, character.only = TRUE)
    render_brew("demo", helpr_demo(package, demo), path = path)
  })
  
  # Individual topic source
  router$get("/package/:package/topic/:topic/source/:func", function(package, topic, func) {
    require(package, character.only = TRUE)
    render_brew("source", helpr_function(package, func), path = path)
  })

  # Individual help topic
  router$get("/package/:package/topic/:topic", function(package, topic) {
    require(package, character.only = TRUE)
    render_brew("topic", helpr_topic(package, topic), path = path)
  })

  # Individual help topic 
  router$get("/library/:package/html/:topic.html", function(package, topic) {
    redirect(str_join("/package/", package, "/topic/", topic))
  })
  router$get("/library/:package/help/:topic", function(package, topic) {
    redirect(str_join("/package/", package, "/topic/", topic))
  })
  
  # AJAX
  router$get("/package/old.json", function() {
    render_json(old_package_names())
  })
  router$get("/package/index.json", function() {
    render_json(installed_packages())
  })
  router$get("/package/update.json/:all_packs", function(all_packs) {
    render_json(update_loaded_packs(all_packs))
  })
  router$get("/package/:package/rating.json", function(package) {
#    render_json(rating_text(as.character(package)))
    string <- rating_text(package)
    render_json(string)
  })
  router$get("/package/:package/exec_demo/:demo", function(package, demo) {
    require(package, character.only = TRUE)
    exec_pkg_demo(package, demo)
    render_json(TRUE)
  })
  router$get("/package/:package/topic/:topic/exec_example", function(package, topic) {
    require(package, character.only = TRUE)
    exec_example(package, topic)
    render_json(TRUE)
  })

  
  
  # Manual HTML Files
  router$get("/manuals/:name.html", function(name) {
    file_loc <- as.character(subset(get_manuals(), file_name == name, select = "file_loc"))
    static_file(file_loc)
  })
  
  #execute code  
  router$get("/eval_text/:encoded_text", function(encoded_text){
    cat("\n")
    evaluate:::replay.list(evaluate:::evaluate(URLdecode(encoded_text), envir = .GlobalEnv))
    cat(options("prompt")$prompt)

    render_json(TRUE)
  })
  
  # Individual help topic 
  router$get("/g", function() {
    redirect("package/stats/demo/glm.vr")
  })
  router$get("/n", function() {
    redirect("package/stats/topic/nlm")
  })
  

  render_path <- function(path, ...) router$route(path)
  assignInNamespace("httpd", render_path, "tools")
  if (tools:::httpdPort == 0L) {
    help.start()
    options("help_type" = "html")
  }

  return(invisible(router))
}


#' Helpr Home
#'
#' @return all the information necessary to produce the home site ("index.html")
helpr_home <- function(){

  ten_funcs <- ten_functions()

  last_ten_length <- NROW(ten_funcs$last_ten)
  top_ten_length <- NROW(ten_funcs$top_ten)

  list(
    packages = as.list(installed_packages()), 
    last_ten_funcs_str = pluralize(
      "Last Function", 
      bool_statement = (last_ten_length > 1), 
      plural = str_join("Last ", last_ten_length, " Functions")
    ),
    last_ten_funcs = ten_funcs$last_ten,
    top_ten_funcs_str = pluralize(
      "Top Function", 
      bool_statement = (top_ten_length > 1), 
      plural = str_join("Top ", top_ten_length, " Functions")
    ),
    top_ten_funcs = ten_funcs$top_ten,
    manuals = get_manuals()
  )
}
