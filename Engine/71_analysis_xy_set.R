# cleanup the environment ----
rm(list = ls())
if (!is.null(dev.list())) dev.off()
options(survey.lonely.psu="adjust")
cat("\014")
start_time <- Sys.time()

# capture variable coming from vba ----
args <- commandArgs(trailingOnly=T)

# set working director ----
setwd(do.call(file.path, as.list(strsplit(args[1], "\\|")[[1]])))

# load environment ----
load("env_small.RData")

source(file.path(g_excel_backend_temp_nospace_dir_rf, "00_functions.R"))

# load libraries ----
error = f_libraries(
  necessary.std = c("dplyr", "rlang", "ggplot2", "gridExtra", "glue", "tibble"),
  necessary.github = c()
)
glue::glue("RUNNING R SERVER ...") %>% print()
glue::glue("Package status: {error}") %>% print()
glue::glue("\n") %>% print()

# Log of run ----
glue::glue("===================== Running '71_analyse_xy_set.R' =====================") %>% f_log_string(g_file_log) 
glue::glue("This analyses each combination between a given set of y variables agianst a set of x variables, with default filters") %>% f_log_string(g_file_log)

#====================================================

data <- f_read_xl(g_file_path, namedRegion = "xy_set_all", colNames = T, rowNames = F)

data_y <- data %>% 
  select(consider = 1, y = 3, s = 4, descr = 5) %>% 
  mutate(consider = as.numeric(consider)) %>%
  filter(consider == 1) %>% 
  select(-consider) %>% 
  unique()

data_x <- data %>% 
  select(consider = 6, x = 8, descr = 9) %>% 
  mutate(consider = as.numeric(consider)) %>%
  filter(consider == 1) %>% 
  select(-consider) %>% 
  unique()

all_y <- data_y %>% 
  pull(y)

all_x <- data_x %>% 
  pull(x)

all_s <- data_y %>% 
  pull(s)

desc_y <- data_y %>% 
  pull("descr")

desc_x <- data_x %>% 
  pull("descr")

if (length(all_y) == 0){
  print("ERROR: No [Y] Variable specified! Please assign atleast one [Y] variable")
  Sys.sleep(3)
  stop()
}

str_temp <- ifelse(length(all_x) > 1, paste0("each of the ", length(all_x)), "the")
print(glue::glue("Summarising {length(all_y)} [Y] variable(s) for {str_temp} [X] variable(s) ..."))

pb <- txtProgressBar(min = 0, max = length(all_y) * length(all_x), style = 3, width = 40)

i = 0

graph <- list()

for (n_y in 1:length(all_y)){
  s = all_s[[n_y]]
  y = all_y[[n_y]]
  y_sym = all_y[[n_y]] %>% 
    rlang::sym()
  y_label = desc_y[[n_y]]
  
  numeric_y = ifelse(class(d_02[[y]]) == "numeric", T, F)
  
  filter_y <- d_skip %>% 
    filter(q_no == y) %>% 
    pull(condition)
  
  filter_y <- ifelse(rlang::is_empty(filter_y), "T", glue::glue("({trimws(filter_y)})"))
  
    x_sym = character(0)
    
    x_label = "Overall"
    
    answer <- d_02 %>% 
      f_answer_creator(s, y_sym, filter_y, x_sym) %>% 
      suppressWarnings() 
    
    graph[[length(graph) + 1]] <- answer %>% 
      f_graph_1(x_sym, x_label, y_label, filter_y, numeric_y)
    
    i = i + 1
    setTxtProgressBar(pb, i)

  for (n_x in 1:length(all_x)){
    x_sym = all_x[[n_x]]
    
    x_label = desc_x[[n_x]]
      
    answer <- d_02 %>% 
      f_answer_creator(s, y_sym, filter_y, x_sym) %>% 
      suppressWarnings() 
    
    graph[[length(graph) + 1]] <- answer %>% 
      f_graph_1(x_sym, x_label, y_label, filter_y, numeric_y)
    
    i = i + 1
    setTxtProgressBar(pb, i)
  }
}

graph %>% 
  f_plotter(g_excel_frontend_dir)

#====================================================

# Log of run ----
glue::glue("finished run in {round(Sys.time() - start_time, 0)} secs") %>% f_log_string(g_file_log)
glue::glue("\n\n") %>% f_log_string(g_file_log)

# remove unnecessary variables from environment ----
rm(list = setdiff(ls(), ls(pattern = "^(d_|g_|f_)")))

# save environment in a session temp variable ----
save.image(file=file.path(g_wd, "env_small.RData"))

print(glue::glue("\n\n All done!"))
for(i in 1:3){
  print(glue::glue("Finishing in: {4 - i} sec"))
  Sys.sleep(1)
}
