#include "ruby.h"
//#include "ext_help.h"
#include <errno.h>
#include <inttypes.h>
#include "hdr_histogram.h"

#define GET_HDRHIST(name, val)         \
  struct hdr_histogram    *name;       \
  Data_Get_Struct(val, struct hdr_histogram, name)

static VALUE HDRHistogram = Qnil;
static VALUE HDRHistogramError = Qnil;

static void histogram_free(void *p) {
  free(p);
}

static VALUE histogram_new(int argc, VALUE* argv, VALUE class) {
  VALUE                    self, lowest_value, highest_value, significant_figures;
  VALUE                    opt;
  
  struct hdr_histogram    *hdrh;
  int                      ret;
  
  rb_scan_args(argc, argv, "31", &lowest_value, &highest_value, &significant_figures, &opt);
  
  lowest_value = rb_funcall(class, rb_intern("adjusted_boundary_val"), 2, lowest_value, opt);
  highest_value = rb_funcall(class, rb_intern("adjusted_boundary_val"), 2, highest_value, opt);
  
  ret = hdr_init(NUM2INT(lowest_value), NUM2INT(highest_value), NUM2INT(significant_figures), &hdrh);
  if(ret == EINVAL) {
    rb_raise(HDRHistogramError, "%s", "lowest_trackable_value must be >= 1");
  }
  else if(ret == ENOMEM) {
    rb_raise(HDRHistogramError, "%s", "no memory");
  }
  
  self = Data_Wrap_Struct(class, NULL, histogram_free, hdrh);
  rb_obj_call_init(self, argc, argv);
  
  return self;
}

static VALUE histogram_reset(VALUE self) {
  GET_HDRHIST(hdr, self);
  hdr_reset(hdr);
  return self;
}

static VALUE histogram_memsize(VALUE self) {
  GET_HDRHIST(hdr, self);
  return INT2NUM(hdr_get_memory_size(hdr));
}

static VALUE histogram_count(VALUE self) {
  GET_HDRHIST(hdr, self);
  return INT2NUM(hdr->total_count);
}

static VALUE histogram_record_value(VALUE self, VALUE val) {
  GET_HDRHIST(hdr, self);
  return hdr_record_value(hdr, NUM2INT(val)) ? Qtrue : Qfalse;
}

static VALUE histogram_record_corrected_value(VALUE self, VALUE val, VALUE expected_interval) {
  GET_HDRHIST(hdr, self);
  return hdr_record_corrected_value(hdr, NUM2INT(val), NUM2INT(expected_interval)) ? Qtrue : Qfalse;
}

static VALUE generic_histogram_intval(VALUE self, int64_t func(const struct hdr_histogram *) ) {
  GET_HDRHIST(hdr, self);
  return INT2NUM(hdr->total_count > 0 ? func(hdr) : 0);
}

static VALUE histogram_min(VALUE self) {
  return generic_histogram_intval(self, hdr_min);
}
static VALUE histogram_max(VALUE self) {
  return generic_histogram_intval(self, hdr_max);
}

static VALUE generic_histogram_floatval(VALUE self, double func(const struct hdr_histogram *) ) {
  GET_HDRHIST(hdr, self);
  return rb_float_new(hdr->total_count > 0 ? func(hdr) : 0.0);
}

static VALUE histogram_mean(VALUE self) {
  return generic_histogram_floatval(self, hdr_mean);
}

static VALUE histogram_stddev(VALUE self) {
  return generic_histogram_floatval(self, hdr_stddev);
}

static VALUE histogram_percentile(VALUE self, VALUE percentile ) {
  GET_HDRHIST(hdr, self);
  return INT2NUM(hdr_value_at_percentile(hdr, NUM2DBL(percentile)));
}

static VALUE histogram_merge(VALUE self, VALUE another ) {
  GET_HDRHIST(hdr, self);
  GET_HDRHIST(hdr2, another);
  return INT2NUM(hdr_add(hdr, hdr2));
}

#define HISTOGRAM_GETSETNUM_METHOD(num_name, num_type)       \
static VALUE histogram_get_##num_name(VALUE self) {       \
  GET_HDRHIST(hdr, self);                                 \
  return num_type##2NUM(hdr->num_name);                   \
}                                                         \
                                                          \
static VALUE histogram_set_##num_name(VALUE self, VALUE num) { \
  GET_HDRHIST(hdr, self);                                 \
  hdr->num_name = NUM2##num_type(num);                    \
  return Qtrue;                                           \
}

HISTOGRAM_GETSETNUM_METHOD(lowest_trackable_value, LL)
HISTOGRAM_GETSETNUM_METHOD(highest_trackable_value, LL)
HISTOGRAM_GETSETNUM_METHOD(unit_magnitude, LONG)
HISTOGRAM_GETSETNUM_METHOD(significant_figures, LONG)
HISTOGRAM_GETSETNUM_METHOD(sub_bucket_half_count_magnitude, LONG)
HISTOGRAM_GETSETNUM_METHOD(sub_bucket_half_count, LONG)
HISTOGRAM_GETSETNUM_METHOD(sub_bucket_mask, LL)
HISTOGRAM_GETSETNUM_METHOD(sub_bucket_count, LONG)
HISTOGRAM_GETSETNUM_METHOD(bucket_count, LONG)
HISTOGRAM_GETSETNUM_METHOD(min_value, LL)
HISTOGRAM_GETSETNUM_METHOD(max_value, LL)
HISTOGRAM_GETSETNUM_METHOD(normalizing_index_offset, LONG)
HISTOGRAM_GETSETNUM_METHOD(conversion_ratio, DBL)
HISTOGRAM_GETSETNUM_METHOD(counts_len, LONG)
HISTOGRAM_GETSETNUM_METHOD(total_count, LL)

#define HISTOGRAM_RUBY_PRIVATE_GETSETTERS(num_name) \
  rb_define_private_method(HDRHistogram, #num_name "=", histogram_set_##num_name, 1);\
  rb_define_private_method(HDRHistogram, #num_name, histogram_get_##num_name, 0)


static VALUE histogram_set_raw_count(VALUE self, VALUE index, VALUE count) {
  GET_HDRHIST(hdr, self);
  int     i = NUM2INT(index);
  int64_t c = NUM2LL(count);
  hdr->counts[i]=c;
  return Qtrue;
}
static VALUE histogram_get_raw_count(VALUE self, VALUE index) {
  VALUE   count;
  int     i = NUM2INT(index);
  GET_HDRHIST(hdr, self);
  if(i >= hdr->counts_len) {
    return Qnil;
  }
  else {
    count = LL2NUM(hdr->counts[i]);
    return count;
  }
}

void Init_ruby_hdr_histogram() {
  HDRHistogram = rb_define_class("HDRHistogram", rb_cObject);
  HDRHistogramError = rb_define_class_under(HDRHistogram, "HDRHistogramError", rb_eRuntimeError);
  
  rb_define_singleton_method(HDRHistogram, "new", histogram_new, -1);
  rb_define_attr(HDRHistogram, "multiplier", 1, 0);
  rb_define_attr(HDRHistogram, "unit", 1, 0);
  
  rb_define_method(HDRHistogram, "reset", histogram_reset, 0);
  rb_define_method(HDRHistogram, "memsize", histogram_memsize, 0);
  rb_define_method(HDRHistogram, "count", histogram_count, 0);
  
  rb_define_private_method(HDRHistogram, "raw_record", histogram_record_value, 1);
  rb_define_private_method(HDRHistogram, "raw_record_corrected", histogram_record_corrected_value, 2);
  rb_define_private_method(HDRHistogram, "raw_min", histogram_min, 0);
  rb_define_private_method(HDRHistogram, "raw_max", histogram_max, 0);
  rb_define_private_method(HDRHistogram, "raw_mean", histogram_mean, 0);
  rb_define_private_method(HDRHistogram, "raw_stddev", histogram_stddev, 0);
  rb_define_private_method(HDRHistogram, "raw_percentile", histogram_percentile, 1);
  rb_define_private_method(HDRHistogram, "raw_merge", histogram_merge, 1);
  
  HISTOGRAM_RUBY_PRIVATE_GETSETTERS(lowest_trackable_value);
  HISTOGRAM_RUBY_PRIVATE_GETSETTERS(highest_trackable_value);
  HISTOGRAM_RUBY_PRIVATE_GETSETTERS(unit_magnitude);
  HISTOGRAM_RUBY_PRIVATE_GETSETTERS(significant_figures);
  HISTOGRAM_RUBY_PRIVATE_GETSETTERS(sub_bucket_half_count_magnitude);
  HISTOGRAM_RUBY_PRIVATE_GETSETTERS(sub_bucket_half_count);
  HISTOGRAM_RUBY_PRIVATE_GETSETTERS(sub_bucket_mask);
  HISTOGRAM_RUBY_PRIVATE_GETSETTERS(sub_bucket_count);
  HISTOGRAM_RUBY_PRIVATE_GETSETTERS(bucket_count);
  HISTOGRAM_RUBY_PRIVATE_GETSETTERS(min_value);
  HISTOGRAM_RUBY_PRIVATE_GETSETTERS(max_value);
  HISTOGRAM_RUBY_PRIVATE_GETSETTERS(normalizing_index_offset);
  HISTOGRAM_RUBY_PRIVATE_GETSETTERS(conversion_ratio);
  HISTOGRAM_RUBY_PRIVATE_GETSETTERS(counts_len);
  HISTOGRAM_RUBY_PRIVATE_GETSETTERS(total_count);
  
  rb_define_private_method(HDRHistogram, "set_raw_count", histogram_set_raw_count, 2);
  rb_define_private_method(HDRHistogram, "get_raw_count", histogram_get_raw_count, 1);
}

